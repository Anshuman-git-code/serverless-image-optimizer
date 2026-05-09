# ─────────────────────────────────────────────
# CREATE REST API
# Equivalent to: aws apigateway create-rest-api --name "ImagePipelineAPI" ...
# ─────────────────────────────────────────────

resource "aws_api_gateway_rest_api" "image_pipeline" {
  name        = "ImagePipelineAPI"
  description = "API for Image Processing Pipeline"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Project = "image-optimization-pipeline"
  }
}

# ─────────────────────────────────────────────
# /generate-upload-url RESOURCE
# Equivalent to: aws apigateway create-resource --path-part "generate-upload-url"
# aws_api_gateway_rest_api.image_pipeline.root_resource_id = the "/" root resource ID
# (In your CLI guide this was the ROOT_ID variable)
# ─────────────────────────────────────────────

resource "aws_api_gateway_resource" "generate_upload_url" {
  rest_api_id = aws_api_gateway_rest_api.image_pipeline.id
  parent_id   = aws_api_gateway_rest_api.image_pipeline.root_resource_id
  path_part   = "generate-upload-url"
}

# ─────────────────────────────────────────────
# POST METHOD on /generate-upload-url
# Equivalent to: aws apigateway put-method --http-method POST --authorization-type NONE
# ─────────────────────────────────────────────

resource "aws_api_gateway_method" "post_generate_upload_url" {
  rest_api_id   = aws_api_gateway_rest_api.image_pipeline.id
  resource_id   = aws_api_gateway_resource.generate_upload_url.id
  http_method   = "POST"
  authorization = "NONE"
}

# ─────────────────────────────────────────────
# AWS_PROXY INTEGRATION — wires POST to Lambda 1
# Equivalent to: aws apigateway put-integration --type AWS_PROXY ...
# In your CLI guide this step failed with "AWS ARN must contain path or action"
# because the Lambda ARN variable wasn't expanding correctly in the URI string.
# Terraform uses aws_lambda_function.generate_upload_url.invoke_arn which is
# ALREADY in the correct URI format — no manual ARN construction needed.
# ─────────────────────────────────────────────

resource "aws_api_gateway_integration" "post_generate_upload_url_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.image_pipeline.id
  resource_id             = aws_api_gateway_resource.generate_upload_url.id
  http_method             = aws_api_gateway_method.post_generate_upload_url.http_method
  integration_http_method = "POST" # Lambda integration always uses POST internally
  type                    = "AWS_PROXY"

  # invoke_arn is the correct API Gateway integration URI — Terraform builds it for you
  # In your CLI guide you had to manually construct:
  # "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$LAMBDA1_ARN/invocations"
  # And it kept breaking because $LAMBDA1_ARN wasn't expanding inside the string
  uri = aws_lambda_function.generate_upload_url.invoke_arn
}

# Grant API Gateway permission to invoke Lambda 1
# Equivalent to: aws lambda add-permission --principal apigateway.amazonaws.com
resource "aws_lambda_permission" "apigw_invoke_generate_upload_url" {
  statement_id  = "APIGatewayInvokeGenerateUploadUrl"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_upload_url.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.image_pipeline.execution_arn}/*/*"
}

# ─────────────────────────────────────────────
# CORS OPTIONS METHOD — browsers send this preflight before the real POST
# Equivalent to the 4 put-method / put-integration / put-method-response /
# put-integration-response commands in your CLI guide for CORS
# ─────────────────────────────────────────────

resource "aws_api_gateway_method" "options_generate_upload_url" {
  rest_api_id   = aws_api_gateway_rest_api.image_pipeline.id
  resource_id   = aws_api_gateway_resource.generate_upload_url.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# MOCK integration — returns CORS headers without invoking Lambda
resource "aws_api_gateway_integration" "options_generate_upload_url_mock" {
  rest_api_id = aws_api_gateway_rest_api.image_pipeline.id
  resource_id = aws_api_gateway_resource.generate_upload_url.id
  http_method = aws_api_gateway_method.options_generate_upload_url.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_generate_upload_url_200" {
  rest_api_id = aws_api_gateway_rest_api.image_pipeline.id
  resource_id = aws_api_gateway_resource.generate_upload_url.id
  http_method = aws_api_gateway_method.options_generate_upload_url.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false
    "method.response.header.Access-Control-Allow-Methods" = false
    "method.response.header.Access-Control-Allow-Origin"  = false
  }
}

resource "aws_api_gateway_integration_response" "options_generate_upload_url_response" {
  rest_api_id = aws_api_gateway_rest_api.image_pipeline.id
  resource_id = aws_api_gateway_resource.generate_upload_url.id
  http_method = aws_api_gateway_method.options_generate_upload_url.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    # Note the inner single quotes inside the double-quoted string
    # This is correct HCL syntax — the inner quotes become literal single quotes in the response header
    # In your CLI guide this required the complex '"'"' escaping pattern
  }

  depends_on = [aws_api_gateway_integration.options_generate_upload_url_mock]
}

# ─────────────────────────────────────────────
# /processed-images PARENT RESOURCE
# ─────────────────────────────────────────────

resource "aws_api_gateway_resource" "processed_images" {
  rest_api_id = aws_api_gateway_rest_api.image_pipeline.id
  parent_id   = aws_api_gateway_rest_api.image_pipeline.root_resource_id
  path_part   = "processed-images"
}

# ─────────────────────────────────────────────
# {filename} PATH PARAMETER CHILD RESOURCE
# Equivalent to: create-resource --path-part "{filename}"
# ─────────────────────────────────────────────

resource "aws_api_gateway_resource" "filename" {
  rest_api_id = aws_api_gateway_rest_api.image_pipeline.id
  parent_id   = aws_api_gateway_resource.processed_images.id
  path_part   = "{filename}"
  # Curly braces make this a path parameter
  # When request comes in for /processed-images/photo.jpg
  # API Gateway captures "photo.jpg" as event["pathParameters"]["filename"]
}

# GET METHOD
resource "aws_api_gateway_method" "get_processed_images" {
  rest_api_id   = aws_api_gateway_rest_api.image_pipeline.id
  resource_id   = aws_api_gateway_resource.filename.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.filename" = true # mark filename path param as required
  }
}

# AWS_PROXY integration to Lambda 3
resource "aws_api_gateway_integration" "get_processed_images_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.image_pipeline.id
  resource_id             = aws_api_gateway_resource.filename.id
  http_method             = aws_api_gateway_method.get_processed_images.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_processed_images.invoke_arn
}

# Grant API Gateway permission to invoke Lambda 3
resource "aws_lambda_permission" "apigw_invoke_get_processed_images" {
  statement_id  = "APIGatewayInvokeGetProcessedImages"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_processed_images.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.image_pipeline.execution_arn}/*/*"
}

# CORS OPTIONS method for /processed-images/{filename}
resource "aws_api_gateway_method" "options_filename" {
  rest_api_id   = aws_api_gateway_rest_api.image_pipeline.id
  resource_id   = aws_api_gateway_resource.filename.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_filename_mock" {
  rest_api_id = aws_api_gateway_rest_api.image_pipeline.id
  resource_id = aws_api_gateway_resource.filename.id
  http_method = aws_api_gateway_method.options_filename.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_filename_200" {
  rest_api_id = aws_api_gateway_rest_api.image_pipeline.id
  resource_id = aws_api_gateway_resource.filename.id
  http_method = aws_api_gateway_method.options_filename.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false
    "method.response.header.Access-Control-Allow-Methods" = false
    "method.response.header.Access-Control-Allow-Origin"  = false
  }
}

resource "aws_api_gateway_integration_response" "options_filename_response" {
  rest_api_id = aws_api_gateway_rest_api.image_pipeline.id
  resource_id = aws_api_gateway_resource.filename.id
  http_method = aws_api_gateway_method.options_filename.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.options_filename_mock]
}

# ─────────────────────────────────────────────
# API GATEWAY DEPLOYMENT — REST API v1 requires an explicit deployment step
# In your CLI guide: "If you make any change to the API, you MUST run create-deployment again"
# and "Forgetting this is the most common source of confusion in API Gateway v1"
#
# Terraform solution: the triggers block hashes all API resources.
# Whenever ANY method, integration, or CORS config changes,
# the hash changes → Terraform creates a new deployment → changes go live automatically.
# You never forget.
# ─────────────────────────────────────────────

resource "aws_api_gateway_deployment" "prod" {
  rest_api_id = aws_api_gateway_rest_api.image_pipeline.id
  stage_name  = "prod"

  triggers = {
    # This is a hash of all the API resources, methods, and integrations
    # If ANY of them change, redeployment = sha1(new hash) → triggers a new deployment
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.generate_upload_url.id,
      aws_api_gateway_resource.processed_images.id,
      aws_api_gateway_resource.filename.id,
      aws_api_gateway_method.post_generate_upload_url.id,
      aws_api_gateway_method.get_processed_images.id,
      aws_api_gateway_method.options_generate_upload_url.id,
      aws_api_gateway_method.options_filename.id,
      aws_api_gateway_integration.post_generate_upload_url_lambda.id,
      aws_api_gateway_integration.get_processed_images_lambda.id,
      aws_api_gateway_integration.options_generate_upload_url_mock.id,
      aws_api_gateway_integration.options_filename_mock.id,
    ]))
  }

  # create_before_destroy = create the new deployment before destroying the old one
  # This prevents a brief window where the API has no active stage during redeployment
  lifecycle {
    create_before_destroy = true
  }

  # Deployment depends on ALL methods and integrations being fully configured first
  depends_on = [
    aws_api_gateway_integration.post_generate_upload_url_lambda,
    aws_api_gateway_integration.get_processed_images_lambda,
    aws_api_gateway_integration_response.options_generate_upload_url_response,
    aws_api_gateway_integration_response.options_filename_response,
  ]
}