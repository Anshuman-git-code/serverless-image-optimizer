#!/bin/bash
# scripts/package-pillow.sh
# Run this ONCE before terraform apply to prepare the Pillow Lambda package
# Re-run only when requirements.txt changes

set -e   # exit immediately if any command fails

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PKG_DIR="$PROJECT_ROOT/build/image-processor-pkg"

echo "📦 Installing Pillow for Lambda Linux runtime..."

# Remove old package to ensure clean install
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR"

# Install Pillow with the Linux platform flag (CRITICAL — see CLI guide for why)
pip3 install pillow \
  --target "$PKG_DIR" \
  --platform manylinux2014_x86_64 \
  --implementation cp \
  --python-version 3.11 \
  --only-binary=:all: \
  --upgrade

# Copy Lambda source code into the package directory
cp "$PROJECT_ROOT/lambda-functions/image-processor/lambda_function.py" "$PKG_DIR/"

echo "✅ Pillow package ready at: $PKG_DIR"
echo "   Now run: cd terraform && terraform apply"