variable "suffix" {
  description = "Your unique name suffix for all S3 bucket names. Must be globally unique."
  type        = string
  default     = "anshuman"
  # Change "anshuman" to your name/initials when redeploying
  # This replaces the: export SUFFIX="anshuman" shell command
  # that you had to remember to run every terminal session
}

variable "region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
  # This replaces: export REGION="ap-south-1"
}

variable "compression_quality" {
  description = "JPEG compression quality for the image processor Lambda (1-100)"
  type        = number
  default     = 85
}

variable "lambda_timeout_processor" {
  description = "Timeout in seconds for the image processor Lambda"
  type        = number
  default     = 59
}

variable "lambda_timeout_simple" {
  description = "Timeout for URL generator Lambdas (they are instant)"
  type        = number
  default     = 10
}