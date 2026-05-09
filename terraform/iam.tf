# ─────────────────────────────────────────────
# IAM ROLE — the identity that all 3 Lambda functions assume at runtime
# ─────────────────────────────────────────────

resource "aws_iam_role" "lambda_role" {
  name = "Lambda-Image-Processing-Role"

  # assume_role_policy = the trust policy
  # This says: "the Lambda service is allowed to assume this role"
  # Equivalent to the --assume-role-policy-document argument in aws iam create-role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = "image-optimization-pipeline"
  }
}

# ─────────────────────────────────────────────
# ATTACH CLOUDWATCH LOGS POLICY (built-in AWS managed policy)
# Equivalent to: aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/...AWSLambdaBasicExecutionRole
# ─────────────────────────────────────────────

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  # This attaches the AWS-managed policy that grants CloudWatch Logs access
  # Without this your Lambda functions run silently — no logs, no debugging
}

# ─────────────────────────────────────────────
# INLINE S3 POLICY — custom permissions for this specific project
# Equivalent to: aws iam put-role-policy with the JSON that kept breaking
# due to single-quote/double-quote variable expansion in zsh
# ─────────────────────────────────────────────

resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "S3ImagePipelineAccess"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Lambda 2 (ImageProcessor) needs GetObject to download original image
        # Lambda 2 needs PutObject to upload processed images
        # Lambda 3 (get-processed-images) needs HeadObject to check if files exist
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:HeadObject"]
        Resource = [
          "arn:aws:s3:::${local.input_bucket}/*",
          "arn:aws:s3:::${local.output_bucket}/*"
          # local.input_bucket and local.output_bucket are defined in main.tf
          # They ALWAYS expand to the correct values — no shell quoting issues
        ]
      },
      {
        # Pre-signed URL generation is a client-side SDK operation
        # It needs "*" as Resource because it's a signing operation, not an S3 API call
        Effect   = "Allow"
        Action   = "s3:GeneratePresignedUrl"
        Resource = "*"
      }
    ]
  })
}
