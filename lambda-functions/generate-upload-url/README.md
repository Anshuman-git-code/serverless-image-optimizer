# Generate Upload URL Lambda Function

This Lambda function generates pre-signed S3 URLs for secure image uploads.

## Functionality

- Receives filename and content type from API Gateway
- Generates pre-signed S3 PUT URL
- Returns URL with 15-minute expiry

## Configuration

**Runtime**: Python 3.11  
**Memory**: 128 MB  
**Timeout**: 10 seconds  
**Handler**: lambda_function.lambda_handler

## API Integration

**Method**: POST  
**Path**: /generate-upload-url

**Request**:
```json
{
  "filename": "image.jpg",
  "contentType": "image/jpeg"
}
```

**Response**:
```json
{
  "uploadUrl": "https://s3.amazonaws.com/...",
  "filename": "image.jpg"
}
```

## Deployment

```bash
zip function.zip lambda_function.py
aws lambda update-function-code \
  --function-name generate-upload-url \
  --zip-file fileb://function.zip
```
