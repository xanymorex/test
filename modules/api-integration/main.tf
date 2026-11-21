resource "aws_api_gateway_integration" "public_lambda" {
  rest_api_id             = var.public_api_id
  resource_id             = var.public_resource_id
  http_method             = var.public_method_http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.public_lambda_invoke_arn
}

resource "aws_lambda_permission" "public_api" {
  statement_id  = "AllowPublicApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.public_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:*:*:${var.public_api_id}/*/POST/process"
}

resource "aws_api_gateway_integration" "isolated_lambda" {
  rest_api_id             = var.private_api_id
  resource_id             = var.private_resource_id
  http_method             = var.private_method_http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.isolated_lambda_invoke_arn
}

resource "aws_lambda_permission" "private_api" {
  statement_id  = "AllowPrivateApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.isolated_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:*:*:${var.private_api_id}/*/POST/process"
}

resource "aws_api_gateway_deployment" "public" {
  rest_api_id = var.public_api_id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.public_lambda.id,
      var.public_method_http_method
    ]))
  }
  lifecycle { create_before_destroy = true }
  depends_on = [aws_api_gateway_integration.public_lambda]
}

resource "aws_api_gateway_stage" "public" {
  deployment_id = aws_api_gateway_deployment.public.id
  rest_api_id   = var.public_api_id
  stage_name    = "v1"
  access_log_settings {
    destination_arn = var.public_api_log_group_arn
    format = jsonencode({
      requestId = "$context.requestId"
      sourceIp = "$context.identity.sourceIp"
      requestTime = "$context.requestTime"
      httpMethod = "$context.httpMethod"
      resourcePath = "$context.resourcePath"
      status = "$context.status"
      responseLength = "$context.responseLength"
    })
  }
}

resource "aws_api_gateway_deployment" "private" {
  rest_api_id = var.private_api_id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.isolated_lambda.id,
      var.private_method_http_method
    ]))
  }
  lifecycle { create_before_destroy = true }
  depends_on = [aws_api_gateway_integration.isolated_lambda]
}

resource "aws_api_gateway_stage" "private" {
  deployment_id = aws_api_gateway_deployment.private.id
  rest_api_id   = var.private_api_id
  stage_name    = "v1"
  access_log_settings {
    destination_arn = var.private_api_log_group_arn
    format = jsonencode({
      requestId = "$context.requestId"
      sourceIp = "$context.identity.sourceIp"
      requestTime = "$context.requestTime"
      httpMethod = "$context.httpMethod"
      resourcePath = "$context.resourcePath"
      status = "$context.status"
    })
  }
}

output "public_stage_arn" { value = aws_api_gateway_stage.public.arn }
