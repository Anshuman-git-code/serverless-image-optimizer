# Get Processed Images Lambda Function

This Lambda function generates pre-signed S3 URLs for downloading processed images.

## Functionality

- Receives filename from API Gateway
- Generates pre-signed S3 GET URLs for all resolutions
- Returns URLs with 1-hour expiry

## Configuration

**Runtime**: Python 3.11  
**Memory**: 128 MB  
**Timeout**: 10 seconds  
**Handler**: lambda_function.lambda_handler

## API Integration

**Method**: GET  
**Path**: /processed-images/{filename}

**Response**:
```json
{
  "1080p": "https://s3.amazonaws.com/1080p/image.jpg?...",
  "720p": "https://s3.amazonaws.com/720p/image.jpg?...",
  "480p": "https://s3.amazonaws.com/480p/image.jpg?..."
}
```

## Deployment

```bash
zip function.zip lambda_function.py
aws lambda update-function-code \
  --function-name get-processed-images \
  --zip-file fileb://function.zip
```
