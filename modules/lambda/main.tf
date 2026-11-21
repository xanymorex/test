data "archive_file" "public" {
  type        = "zip"
  source_file = "${path.module}/../../lambda-src/public/handler.py"
  output_path = "${path.module}/../../lambda-src/public/function.zip"
}

data "archive_file" "isolated" {
  type        = "zip"
  source_file = "${path.module}/../../lambda-src/isolated/handler.py"
  output_path = "${path.module}/../../lambda-src/isolated/function.zip"
}

resource "aws_iam_role" "public" {
  name = "${var.name}-public-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "public_logs" {
  name = "${var.name}-public-logs"
  role = aws_iam_role.public.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.public.arn}:*"
    }]
  })
}

resource "aws_iam_role_policy" "public_vpc" {
  name = "${var.name}-public-vpc"
  role = aws_iam_role.public.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface", "ec2:AssignPrivateIpAddresses", "ec2:UnassignPrivateIpAddresses"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "public_invoke_private_api" {
  name = "${var.name}-invoke-private-api"
  role = aws_iam_role.public.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "execute-api:Invoke"
      Resource = "${var.private_api_execution_arn}/*/POST/process"
    }]
  })
}

resource "aws_iam_role" "isolated" {
  name = "${var.name}-isolated-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "isolated_logs" {
  name = "${var.name}-isolated-logs"
  role = aws_iam_role.isolated.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.isolated.arn}:*"
    }]
  })
}

resource "aws_iam_role_policy" "isolated_vpc" {
  name = "${var.name}-isolated-vpc"
  role = aws_iam_role.isolated.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface", "ec2:AssignPrivateIpAddresses", "ec2:UnassignPrivateIpAddresses"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "isolated_s3" {
  name = "${var.name}-isolated-s3"
  role = aws_iam_role.isolated.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:PutObject"]
        Resource = "${var.s3_bucket_arn}/processed/*"
      },
      {
        Effect = "Allow"
        Action = ["kms:Encrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
        Resource = var.kms_key_arn
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "public" {
  name              = "/aws/lambda/${var.name}-public-api"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "isolated" {
  name              = "/aws/lambda/${var.name}-isolated-processor"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "public" {
  function_name    = "${var.name}-public-api"
  role             = aws_iam_role.public.arn
  runtime          = "python3.12"
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.public.output_path
  source_code_hash = data.archive_file.public.output_base64sha256
  timeout          = 25
  memory_size      = 256
  architectures    = ["arm64"]

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.public_lambda_sg_id]
  }

  environment {
    variables = {
      PRIVATE_API_URL = var.private_api_url
    }
  }

  depends_on = [aws_iam_role_policy.public_logs, aws_iam_role_policy.public_vpc]
}

resource "aws_lambda_function" "isolated" {
  function_name    = "${var.name}-isolated-processor"
  role             = aws_iam_role.isolated.arn
  runtime          = "python3.12"
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.isolated.output_path
  source_code_hash = data.archive_file.isolated.output_base64sha256
  timeout          = 25
  memory_size      = 256
  architectures    = ["arm64"]

  vpc_config {
    subnet_ids         = var.isolated_subnet_ids
    security_group_ids = [var.isolated_lambda_sg_id]
  }

  environment {
    variables = {
      DATA_BUCKET = var.s3_bucket_name
    }
  }

  depends_on = [aws_iam_role_policy.isolated_logs, aws_iam_role_policy.isolated_vpc, aws_iam_role_policy.isolated_s3]
}

output "public_invoke_arn" { value = aws_lambda_function.public.invoke_arn }
output "public_function_name" { value = aws_lambda_function.public.function_name }
output "isolated_invoke_arn" { value = aws_lambda_function.isolated.invoke_arn }
output "isolated_function_name" { value = aws_lambda_function.isolated.function_name }
output "isolated_role_arn" { value = aws_iam_role.isolated.arn }
