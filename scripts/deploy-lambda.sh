#!/bin/bash

# Deploy Lambda Functions
# Usage: ./deploy-lambda.sh [function-name]
# Example: ./deploy-lambda.sh image-processor

FUNCTION_NAME=$1

if [ -z "$FUNCTION_NAME" ]; then
  echo "Usage: ./deploy-lambda.sh [function-name]"
  echo "Available functions:"
  echo "  - image-processor"
  echo "  - generate-upload-url"
  echo "  - get-processed-images"
  exit 1
fi

LAMBDA_DIR="../lambda-functions/$FUNCTION_NAME"

if [ ! -d "$LAMBDA_DIR" ]; then
  echo "Error: Function directory not found: $LAMBDA_DIR"
  exit 1
fi

echo "Deploying $FUNCTION_NAME Lambda function..."

cd $LAMBDA_DIR

# Install dependencies if requirements.txt exists
if [ -f "requirements.txt" ]; then
  echo "Installing dependencies..."
  pip install -r requirements.txt -t .
fi

# Create deployment package
echo "Creating deployment package..."
zip -r function.zip . -x "*.md" "*.sh" "*.git*"

# Deploy to Lambda
echo "Uploading to AWS Lambda..."
if [ "$FUNCTION_NAME" == "image-processor" ]; then
  aws lambda update-function-code \
    --function-name ImageProcessorLambda-Shivam \
    --zip-file fileb://function.zip
else
  aws lambda update-function-code \
    --function-name $FUNCTION_NAME \
    --zip-file fileb://function.zip
fi

# Cleanup
rm function.zip

echo "$FUNCTION_NAME deployed successfully!"
