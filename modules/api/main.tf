data "aws_caller_identity" "current" {}

resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${var.name}-apigateway-cloudwatch-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "api_gateway_cloudwatch" {
  name = "${var.name}-apigateway-cloudwatch-policy"
  role = aws_iam_role.api_gateway_cloudwatch.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents",
        "logs:GetLogEvents",
        "logs:FilterLogEvents"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

locals {
  private_vpce_id = var.execute_api_vpce_id
}

resource "aws_cloudwatch_log_group" "public_api" {
  name              = "/aws/apigateway/${var.name}-public"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "private_api" {
  name              = "/aws/apigateway/${var.name}-private"
  retention_in_days = 30
}

resource "aws_api_gateway_rest_api" "public" {
  name = "${var.name}-public-api"
  endpoint_configuration { types = ["REGIONAL"] }
}

resource "aws_api_gateway_resource" "public_process" {
  rest_api_id = aws_api_gateway_rest_api.public.id
  parent_id   = aws_api_gateway_rest_api.public.root_resource_id
  path_part   = "process"
}

resource "aws_api_gateway_method" "public_post" {
  rest_api_id   = aws_api_gateway_rest_api.public.id
  resource_id   = aws_api_gateway_resource.public_process.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_rest_api" "private" {
  name = "${var.name}-private-api"
  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [local.private_vpce_id]
  }
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowInvokeFromApprovedVpcEndpoint"
      Effect    = "Allow"
      Principal = "*"
      Action    = "execute-api:Invoke"
      Resource  = "execute-api:/*"
      Condition = { StringEquals = { "aws:SourceVpce" = local.private_vpce_id } }
    }]
  })
}

resource "aws_api_gateway_resource" "private_process" {
  rest_api_id = aws_api_gateway_rest_api.private.id
  parent_id   = aws_api_gateway_rest_api.private.root_resource_id
  path_part   = "process"
}

resource "aws_api_gateway_method" "private_post" {
  rest_api_id   = aws_api_gateway_rest_api.private.id
  resource_id   = aws_api_gateway_resource.private_process.id
  http_method   = "POST"
  authorization = "AWS_IAM"
}

output "public_api_id" { value = aws_api_gateway_rest_api.public.id }
output "public_api_url" { value = "https://${aws_api_gateway_rest_api.public.id}.execute-api.${var.region}.amazonaws.com/v1/process" }
output "public_resource_id" { value = aws_api_gateway_resource.public_process.id }
output "public_method_http_method" { value = aws_api_gateway_method.public_post.http_method }
output "private_api_id" { value = aws_api_gateway_rest_api.private.id }
output "private_resource_id" { value = aws_api_gateway_resource.private_process.id }
output "private_method_http_method" { value = aws_api_gateway_method.private_post.http_method }
output "private_api_url" {
  value = "https://${aws_api_gateway_rest_api.private.id}.execute-api.${var.region}.amazonaws.com/v1/process"
}
output "private_api_execution_arn" { value = aws_api_gateway_rest_api.private.execution_arn }
output "public_api_log_group_arn" { value = aws_cloudwatch_log_group.public_api.arn }
output "private_api_log_group_arn" { value = aws_cloudwatch_log_group.private_api.arn }
