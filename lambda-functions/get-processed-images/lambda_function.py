import boto3
import json
import os

s3 = boto3.client("s3")
resolutions = ["1080p", "720p", "480p"]
OUTPUT_BUCKET = os.environ.get("OUTPUT_BUCKET", "image-pipeline-output-sid")

def lambda_handler(event, context):
    """
    Generate pre-signed URLs for downloading processed images
    
    Args:
        event: API Gateway event with pathParameters containing filename
        context: Lambda context
        
    Returns:
        Pre-signed S3 download URLs for all resolutions (1 hour expiry)
    """
    filename = event["pathParameters"]["filename"]
    bucket = OUTPUT_BUCKET
    
    output = {}

    # Generate pre-signed URL for each resolution
    for r in resolutions:
        key = f"{r}/{filename}"
        url = s3.generate_presigned_url(
            "get_object",
            Params={
                "Bucket": bucket,
                "Key": key
            },
            ExpiresIn=3600  # 1 hour
        )
        output[r] = url

    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*"
        },
        "body": json.dumps(output)
    }
