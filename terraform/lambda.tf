# ─────────────────────────────────────────────
# LAMBDA 1 — generate-upload-url
# No external dependencies (boto3 is pre-installed in Lambda runtime)
# Simple: zip just the .py file
# ─────────────────────────────────────────────

# data "archive_file" creates a ZIP at plan time from source files
# Equivalent to: cd lambda-functions/generate-upload-url && zip function.zip lambda_function.py
data "archive_file" "generate_upload_url_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda-functions/generate-upload-url/lambda_function.py"
  output_path = "${path.module}/../build/generate_upload_url.zip"
  # path.module = the terraform/ directory
  # ../lambda-functions/... navigates up to the project root and into the source
}

resource "aws_lambda_function" "generate_upload_url" {
  function_name = "generate-upload-url"
  role          = aws_iam_role.lambda_role.arn
  # ↑ references the IAM role — Terraform creates the role first automatically

  runtime  = "python3.11"
  handler  = "lambda_function.lambda_handler"
  filename = data.archive_file.generate_upload_url_zip.output_path
  # ↑ references the ZIP created above — Terraform zips first, then creates the function

  # source_code_hash tells Terraform to update the Lambda code
  # whenever the ZIP content changes (not just when you manually tell it to)
  source_code_hash = data.archive_file.generate_upload_url_zip.output_base64sha256

  timeout     = var.lambda_timeout_simple # 10 seconds
  memory_size = 128

  environment {
    variables = {
      # THIS IS THE FIX for the hardcoded "-sid" bucket name bug from your CLI guide
      # local.input_bucket always equals "image-pipeline-input-${var.suffix}"
      # Terraform passes the real bucket name — never a hardcoded stale value
      INPUT_BUCKET = local.input_bucket
    }
  }

  tags = {
    Project = "image-optimization-pipeline"
  }
}

# ─────────────────────────────────────────────
# LAMBDA 3 — get-processed-images
# Same pattern as Lambda 1 — simple ZIP, no dependencies
# ─────────────────────────────────────────────

data "archive_file" "get_processed_images_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda-functions/get-processed-images/lambda_function.py"
  output_path = "${path.module}/../build/get_processed_images.zip"
}

resource "aws_lambda_function" "get_processed_images" {
  function_name = "get-processed-images"
  role          = aws_iam_role.lambda_role.arn

  runtime  = "python3.11"
  handler  = "lambda_function.lambda_handler"
  filename = data.archive_file.get_processed_images_zip.output_path

  source_code_hash = data.archive_file.get_processed_images_zip.output_base64sha256

  timeout     = var.lambda_timeout_simple
  memory_size = 128

  environment {
    variables = {
      OUTPUT_BUCKET = local.output_bucket
      # Again — always the real bucket name, never hardcoded "-sid"
    }
  }

  tags = {
    Project = "image-optimization-pipeline"
  }
}

# ─────────────────────────────────────────────
# LAMBDA 2 — ImageProcessorLambda-Shivam
# Requires Pillow — you ran package-pillow.sh to prepare build/image-processor-pkg/
# The archive_file data source ZIPs that entire directory (Pillow + lambda_function.py)
# ─────────────────────────────────────────────

data "archive_file" "image_processor_zip" {
  type       = "zip"
  source_dir = "${path.module}/../build/image-processor-pkg"
  # ↑ source_dir (not source_file) — ZIPs the entire directory
  # This is equivalent to: cd build/image-processor-pkg && zip -r ../image_processor.zip .
  output_path = "${path.module}/../build/image_processor.zip"
}

resource "aws_lambda_function" "image_processor" {
  function_name = "ImageProcessorLambda-Shivam"
  role          = aws_iam_role.lambda_role.arn

  runtime  = "python3.11"
  handler  = "lambda_function.lambda_handler"
  filename = data.archive_file.image_processor_zip.output_path

  source_code_hash = data.archive_file.image_processor_zip.output_base64sha256
  # source_code_hash is CRITICAL for the image processor
  # Without it, Terraform won't re-deploy Lambda 2 when you update the code
  # — it only checks if the file PATH changed, not the content

  # Higher timeout and memory — same reasoning as your CLI guide:
  # 14 MB image decompressed = 100-200 MB RAM; more memory = more CPU = faster Pillow
  timeout     = var.lambda_timeout_processor # 59 seconds
  memory_size = 1024

  environment {
    variables = {
      OUTPUT_BUCKET       = local.output_bucket
      COMPRESSION_QUALITY = tostring(var.compression_quality) # "85"
      # tostring() because env vars must be strings, but var.compression_quality is a number
    }
  }

  tags = {
    Project = "image-optimization-pipeline"
  }
}