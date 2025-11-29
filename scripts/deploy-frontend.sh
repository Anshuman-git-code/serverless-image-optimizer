#!/bin/bash

# Deploy Frontend to S3
# Usage: ./deploy-frontend.sh

BUCKET_NAME="image-pipeline-frontend-sid"
FRONTEND_DIR="../frontend"

echo "Deploying frontend to S3..."

# Sync files to S3
aws s3 sync $FRONTEND_DIR s3://$BUCKET_NAME/ \
  --exclude "README.md" \
  --delete

echo "Frontend deployed successfully!"
echo "URL: http://$BUCKET_NAME.s3-website.ap-south-1.amazonaws.com"
