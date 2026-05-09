# Part 1: Create the 3 buckets

# ─────────────────────────────────────────────
# INPUT BUCKET — receives original uploaded images via pre-signed URL
# ─────────────────────────────────────────────

resource "aws_s3_bucket" "input_bucket" {
  bucket = local.input_bucket
  # local.input_bucket = "image-pipeline-input-${var.suffix}"
  # Defined in main.tf locals block — change suffix once, updates everywhere

  tags = {
    Name    = "Image Pipeline Input"
    Project = "image-optimization-pipeline"
  }
}

# ─────────────────────────────────────────────
# OUTPUT BUCKET — stores 1080p/, 720p/, 480p/ processed images
# ─────────────────────────────────────────────=

resource "aws_s3_bucket" "output_bucket" {
  bucket = local.output_bucket

  tags = {
    Name    = "Image Pipeline Output"
    Project = "image-optimization-pipeline"
  }
}

# ─────────────────────────────────────────────
# FRONTEND BUCKET — hosts index.html, styles.css, app.js
# ─────────────────────────────────────────────

resource "aws_s3_bucket" "frontend_bucket" {
  bucket = local.frontend_bucket

  tags = {
    Name    = "Image Pipeline Frontend"
    Project = "image-optimization-pipeline"
  }
}

# Part 2: Frontend website hosting

# Enable static website hosting on the frontend bucket
# Equivalent to: aws s3 website s3://$FRONTEND_BUCKET/ --index-document index.html

resource "aws_s3_bucket_website_configuration" "frontend_website" {
  bucket = aws_s3_bucket.frontend_bucket.id
  # ↑ references the frontend bucket by its Terraform local name
  # Terraform automatically creates the website config AFTER the bucket exists

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html" # SPA routing — send 404s to index.html too
  }
}

# Part 3:Frontend public access (two steps — same as CLI guide)

# Step 3a: Disable the "Block Public Access" safety setting
# Equivalent to: aws s3api put-public-access-block --public-access-block-configuration ...
# In your CLI guide this step caused "zsh: unknown file attribute: 3" — Terraform has none of that

resource "aws_s3_bucket_public_access_block" "frontend_public_access" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
  # All false = public access is allowed (required for website hosting)
}

# Step 3b: Attach the public read bucket policy
# Equivalent to the put-bucket-policy command that kept failing with
# MalformedPolicy because of single-quote variable expansion in your CLI guide.
# In Terraform: no quoting issues. ${local.frontend_bucket} ALWAYS expands correctly.

resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id

  # depends_on ensures the public access block is disabled BEFORE we attach the policy
  # Without this, the policy attachment would fail because block_public_policy was still true
  depends_on = [aws_s3_bucket_public_access_block.frontend_public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "arn:aws:s3:::${local.frontend_bucket}/*"
    }]
  })
  # jsonencode() converts HCL objects to JSON strings correctly — no manual escaping
}

# Part 4: CORS on input and output buckets
# CORS on input bucket — allows browsers to PUT files directly via pre-signed URLs
# Equivalent to: aws s3api put-bucket-cors --bucket $INPUT_BUCKET ...

resource "aws_s3_bucket_cors_configuration" "input_cors" {
  bucket = aws_s3_bucket.input_bucket.id

  cors_rule {
    allowed_origins = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

# CORS on output bucket — allows browsers to GET processed images directly
resource "aws_s3_bucket_cors_configuration" "output_cors" {
  bucket = aws_s3_bucket.output_bucket.id

  cors_rule {
    allowed_origins = ["*"]
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}