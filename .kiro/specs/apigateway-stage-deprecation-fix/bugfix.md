# Bugfix Requirements Document

## Introduction

The `aws_api_gateway_deployment.prod` resource in `terraform/apigateway.tf` uses the deprecated `stage_name` argument to implicitly create an API Gateway stage. The AWS Terraform provider now warns that `stage_name` is deprecated and that a dedicated `aws_api_gateway_stage` resource should be used instead. This fix removes the deprecated argument and introduces an explicit `aws_api_gateway_stage` resource, eliminating the deprecation warning while preserving the existing API Gateway stage name, URL structure, and all downstream references.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN Terraform plans or applies the configuration THEN the system emits a deprecation warning: `stage_name is deprecated. Use the aws_api_gateway_stage resource instead.`

1.2 WHEN the `aws_api_gateway_deployment.prod` resource is evaluated THEN the system implicitly creates the `prod` stage via the deprecated `stage_name = "prod"` argument on the deployment resource rather than through a dedicated stage resource.

1.3 WHEN the API Gateway stage is managed implicitly through the deployment resource THEN the system provides no dedicated resource for stage-level configuration (e.g., access logging, caching, throttling), limiting future extensibility.

### Expected Behavior (Correct)

2.1 WHEN Terraform plans or applies the configuration THEN the system SHALL produce no deprecation warnings related to `stage_name` on `aws_api_gateway_deployment.prod`.

2.2 WHEN the configuration is applied THEN the system SHALL manage the `prod` stage through a dedicated `aws_api_gateway_stage.prod` resource that references `aws_api_gateway_deployment.prod`.

2.3 WHEN the `aws_api_gateway_stage.prod` resource is defined THEN the system SHALL expose a dedicated resource for stage-level configuration, replacing the implicit stage created by the deprecated argument.

### Unchanged Behavior (Regression Prevention)

3.1 WHEN the API is deployed THEN the system SHALL CONTINUE TO serve the API under the `prod` stage name, preserving the existing URL path segment.

3.2 WHEN the API Gateway URL is constructed THEN the system SHALL CONTINUE TO produce a base URL of the form `https://{api-id}.execute-api.{region}.amazonaws.com/prod`, matching the hardcoded path in `outputs.tf`.

3.3 WHEN any API resource, method, or integration changes THEN the system SHALL CONTINUE TO trigger a new deployment via the `triggers.redeployment` hash mechanism on `aws_api_gateway_deployment.prod`.

3.4 WHEN the deployment resource is replaced THEN the system SHALL CONTINUE TO use `create_before_destroy = true` to avoid a downtime window during redeployment.

3.5 WHEN the deployment is applied THEN the system SHALL CONTINUE TO depend on all method integrations and integration responses being fully configured before the deployment resource is created.
