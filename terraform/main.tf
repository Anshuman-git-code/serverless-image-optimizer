# terraform block — tells Terraform which version to use
# and which provider plugins to download
terraform {
  required_version = ">= 1.0"   # need Terraform 1.0 or newer

  required_providers {
    aws = {
      source  = "hashicorp/aws"  # download from Terraform registry
      version = "~> 5.0"         # use any 5.x version (not 6.x)
    }
  }
}

# provider block — configures the AWS plugin
# This is the Terraform equivalent of setting export REGION="ap-south-1"
# but it applies to every resource automatically
provider "aws" {
  region = var.region   # references the variable defined in variables.tf
}

# locals block — computed values you use in multiple places
# Like shell variables, but scoped to Terraform and always available
locals {
  input_bucket    = "image-pipeline-input-${var.suffix}"
  output_bucket   = "image-pipeline-output-${var.suffix}"
  frontend_bucket = "image-pipeline-frontend-${var.suffix}"
  account_id      = data.aws_caller_identity.current.account_id
}

# data block — reads your current AWS account ID without hardcoding it
# Equivalent to: ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
data "aws_caller_identity" "current" {}
