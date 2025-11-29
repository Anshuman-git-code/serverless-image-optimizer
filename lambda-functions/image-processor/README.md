# Image Processor Lambda Function

This Lambda function processes uploaded images by resizing them to multiple resolutions and compressing them.

## Functionality

- Triggered automatically by S3 ObjectCreated events
- Downloads original image from input bucket
- Resizes to 3 resolutions (1080p, 720p, 480p)
- Compresses images (quality 85)
- Converts RGBA to RGB (handles PNG transparency)
- Uploads processed images to output bucket

## Configuration

**Runtime**: Python 3.11  
**Memory**: 1024 MB  
**Timeout**: 59 seconds  
**Handler**: lambda_function.lambda_handler

## Environment Variables

- `OUTPUT_BUCKET`: image-pipeline-output-sid
- `COMPRESSION_QUALITY`: 85

## Dependencies

- Pillow 12.0.0 (image processing)
- boto3 (AWS SDK)

## Deployment

```bash
# Install dependencies
pip install -r requirements.txt -t .

# Create deployment package
zip -r function.zip .

# Deploy to Lambda
aws lambda update-function-code \
  --function-name ImageProcessorLambda-Shivam \
  --zip-file fileb://function.zip
```

## Performance

- Small images (< 1 MB): 1-2 seconds
- Medium images (1-10 MB): 2-4 seconds
- Large images (10-50 MB): 3-6 seconds

## Compression Results

- Average: 90-98% file size reduction
- Quality: Minimal visible degradation
- Format: JPEG (quality 85)
