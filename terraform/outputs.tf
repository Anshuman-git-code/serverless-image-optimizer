# Outputs are printed to your terminal after terraform apply completes
# They are also stored in the state file and accessible via: terraform output

output "frontend_url" {
  description = "Your live frontend website URL"
  value       = "http://${local.frontend_bucket}.s3-website.${var.region}.amazonaws.com"
}

output "api_gateway_url" {
  description = "Your API Gateway base URL — paste this into frontend/app.js"
  value       = "https://${aws_api_gateway_rest_api.image_pipeline.id}.execute-api.${var.region}.amazonaws.com/prod"
}

output "api_gateway_id" {
  description = "API Gateway ID — useful for debugging"
  value       = aws_api_gateway_rest_api.image_pipeline.id
}

output "input_bucket_name" {
  description = "S3 input bucket name"
  value       = local.input_bucket
}

output "output_bucket_name" {
  description = "S3 output bucket name"
  value       = local.output_bucket
}

output "lambda_role_arn" {
  description = "IAM role ARN used by all Lambda functions"
  value       = aws_iam_role.lambda_role.arn
}