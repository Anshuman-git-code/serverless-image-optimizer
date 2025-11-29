import boto3
import json

s3 = boto3.client("s3")

def lambda_handler(event, context):
    """
    Generate pre-signed URL for uploading images to S3
    
    Args:
        event: API Gateway event with body containing filename and contentType
        context: Lambda context
        
    Returns:
        Pre-signed S3 upload URL with 15 minute expiry
    """
    body = json.loads(event["body"])
    filename = body["filename"]
    
    # Generate pre-signed URL for PUT operation
    url = s3.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": "image-pipeline-input-sid",
            "Key": filename
        },
        ExpiresIn=900  # 15 minutes
    )

    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*"
        },
        "body": json.dumps({
            "uploadUrl": url,
            "filename": filename
        })
    }
