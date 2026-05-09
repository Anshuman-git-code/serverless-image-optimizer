# ─────────────────────────────────────────────
# STEP 1: Grant S3 permission to invoke the ImageProcessor Lambda
# Equivalent to: aws lambda add-permission --principal s3.amazonaws.com ...
# MUST happen before the S3 notification is configured
# ─────────────────────────────────────────────

resource "aws_lambda_permission" "s3_invoke_image_processor" {
  statement_id  = "S3InvokeImageProcessor"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_processor.function_name
  principal     = "s3.amazonaws.com"

  # Restrict to ONLY your specific input bucket — security best practice
  source_arn     = aws_s3_bucket.input_bucket.arn
  source_account = local.account_id
  # local.account_id comes from data.aws_caller_identity.current.account_id in main.tf
}

# ─────────────────────────────────────────────
# STEP 2: Configure the S3 bucket to fire events to the Lambda
# Equivalent to: aws s3api put-bucket-notification-configuration ...
# ─────────────────────────────────────────────

resource "aws_s3_bucket_notification" "input_bucket_trigger" {
  bucket = aws_s3_bucket.input_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_processor.arn
    events              = ["s3:ObjectCreated:*"]
    # s3:ObjectCreated:* fires on PUT, POST, multipart upload, copy — all upload methods
  }

  # depends_on enforces ordering — S3 cannot validate the notification target
  # unless Lambda has already granted it invoke permission
  # This is the Terraform equivalent of "must run add-permission before put-notification"
  depends_on = [aws_lambda_permission.s3_invoke_image_processor]
}