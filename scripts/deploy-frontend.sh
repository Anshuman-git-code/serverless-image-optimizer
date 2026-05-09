#!/bin/bash
# scripts/deploy-frontend.sh — updated to use Terraform output

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Get bucket name from Terraform output instead of hardcoded value
# This means it automatically uses the right bucket regardless of your suffix
cd "$PROJECT_ROOT/terraform"
BUCKET=$(terraform output -raw frontend_bucket_name 2>/dev/null)

if [ -z "$BUCKET" ]; then
  echo "Error: Could not get frontend_bucket_name from Terraform output."
  echo "Make sure you've run terraform apply first."
  exit 1
fi

REGION=$(terraform output -raw region 2>/dev/null || echo "ap-south-1")

cd "$PROJECT_ROOT"

echo "Deploying frontend to s3://$BUCKET/..."
aws s3 sync frontend/ s3://$BUCKET/ \
  --region "$REGION" \
  --delete \
  --exclude "README.md"

# Fix content types (same as CLI guide)
aws s3 cp s3://$BUCKET/ s3://$BUCKET/ \
  --recursive --exclude "*" --include "*.html" \
  --content-type "text/html" --metadata-directive REPLACE --region "$REGION"

aws s3 cp s3://$BUCKET/ s3://$BUCKET/ \
  --recursive --exclude "*" --include "*.js" \
  --content-type "application/javascript" --metadata-directive REPLACE --region "$REGION"

aws s3 cp s3://$BUCKET/ s3://$BUCKET/ \
  --recursive --exclude "*" --include "*.css" \
  --content-type "text/css" --metadata-directive REPLACE --region "$REGION"

echo ""
echo "✅ Frontend deployed!"
echo "   URL: $(cd terraform && terraform output -raw frontend_url)"