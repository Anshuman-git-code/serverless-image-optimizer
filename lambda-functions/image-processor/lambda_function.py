import json
import boto3
import os
from PIL import Image
import io
import time

# Configuration from Environment Variables
OUTPUT_BUCKET = os.environ.get('OUTPUT_BUCKET', 'image-pipeline-output-sid')
COMPRESSION_QUALITY = int(os.environ.get('COMPRESSION_QUALITY', 85))
RESOLUTIONS = {
    '1080p': (1920, 1080),
    '720p': (1280, 720),
    '480p': (854, 480)
}

s3_client = boto3.client('s3')

def resize_image_and_upload(image, output_key_prefix, target_res):
    """Resizes, compresses, and uploads a single image to S3."""
    
    max_w, max_h = RESOLUTIONS[target_res]
    original_w, original_h = image.size
    ratio = min(max_w / original_w, max_h / original_h)
    new_w = int(original_w * ratio)
    new_h = int(original_h * ratio)

    resized_image = image.resize((new_w, new_h))
    
    # FIX: Convert RGBA to RGB if needed (handles PNG with transparency)
    if resized_image.mode == 'RGBA':
        # Create white background
        rgb_image = Image.new('RGB', resized_image.size, (255, 255, 255))
        # Paste image using alpha channel as mask
        rgb_image.paste(resized_image, mask=resized_image.split()[3])
        resized_image = rgb_image
    elif resized_image.mode != 'RGB':
        # Convert any other mode (grayscale, CMYK, etc.) to RGB
        resized_image = resized_image.convert('RGB')
    
    buffer = io.BytesIO()
    resized_image.save(buffer, format='JPEG', quality=COMPRESSION_QUALITY)
    buffer.seek(0)

    processed_size = buffer.getbuffer().nbytes
    s3_key = f"{target_res}/{output_key_prefix}"

    s3_client.put_object(
        Bucket=OUTPUT_BUCKET,
        Key=s3_key,
        Body=buffer,
        ContentType='image/jpeg'
    )

    return s3_key, processed_size


def lambda_handler(event, context):
    start_time = time.time()
    temp_path = '/tmp/original_image'
    original_key = ''
    original_size = 0
    processed_files = []

    try:
        # 1. Extract Info from S3 Event
        record = event['Records'][0]
        input_bucket = record['s3']['bucket']['name']
        original_key = record['s3']['object']['key']
        original_size = record['s3']['object']['size']
        print(f"Processing file: {original_key} from bucket: {input_bucket}")
        
        # 2. Download Image
        s3_client.download_file(input_bucket, original_key, temp_path)
        original_image = Image.open(temp_path)

        # 3. Process and Upload Loop
        for res_name in RESOLUTIONS.keys():
            s3_key, size = resize_image_and_upload(original_image, original_key, res_name)
            processed_files.append({
                "resolution": res_name, 
                "key": s3_key, 
                "size": size
            })

    except Exception as e:
        print(f"FATAL ERROR: {e}")
        return {'statusCode': 500, 'body': json.dumps({'error': 'Processing failed', 'details': str(e)})}
    
    finally:
        # 4. Cleanup and Metadata Generation
        if os.path.exists(temp_path):
            os.remove(temp_path)

        processing_time = round(time.time() - start_time, 2)
        total_processed_size = sum(f['size'] for f in processed_files)
        compression_ratio = round(1 - (total_processed_size / original_size), 2) if original_size > 0 else 0
        
        print(f"Processing complete in {processing_time}s. Ratio: {compression_ratio}")
    
    # 5. Return Success Metadata
    return {
        "statusCode": 200,
        "body": {
            "originalFile": original_key,
            "processedFiles": processed_files,
            "compressionRatio": compression_ratio,
            "processingTime": processing_time
        }
    }
