data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = length(var.availability_zones) == 2 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)
  common_name = "${var.name_prefix}-${var.environment}"
}

module "networking" {
  source      = "../../modules/networking"
  name        = local.common_name
  vpc_cidr    = var.vpc_cidr
  azs         = local.azs
}

module "security" {
  source = "../../modules/security"
  name   = local.common_name
  vpc_id = module.networking.vpc_id
  vpc_cidr = var.vpc_cidr
  region   = var.aws_region
}

module "endpoints" {
  source                 = "../../modules/endpoints"
  name                   = local.common_name
  vpc_id                 = module.networking.vpc_id
  vpc_cidr               = var.vpc_cidr
  region                 = var.aws_region
  private_route_table_ids = module.networking.private_route_table_ids
  isolated_route_table_ids = module.networking.isolated_route_table_ids
  isolated_subnet_ids    = module.networking.isolated_subnet_ids
  endpoint_security_group_id = module.security.endpoint_sg_id
}

module "storage" {
  source      = "../../modules/storage"
  name        = local.common_name
}

module "api" {
  source = "../../modules/api"
  name   = local.common_name
  region = var.aws_region
  execute_api_vpce_id = module.endpoints.execute_api_vpce_id
}

module "lambda" {
  source = "../../modules/lambda"
  name   = local.common_name
  region = var.aws_region
  private_subnet_ids  = module.networking.private_subnet_ids
  isolated_subnet_ids = module.networking.isolated_subnet_ids
  public_lambda_sg_id = module.security.public_lambda_sg_id
  isolated_lambda_sg_id = module.security.isolated_lambda_sg_id
  log_retention_days = var.log_retention_days
  private_api_url = module.api.private_api_url
  private_api_execution_arn = module.api.private_api_execution_arn
  s3_bucket_arn = module.storage.bucket_arn
  s3_bucket_name = module.storage.bucket_name
  kms_key_arn = module.storage.kms_key_arn
  depends_on = [module.endpoints]
}

module "api_integration" {
  source = "../../modules/api-integration"
  name   = local.common_name
  public_api_id = module.api.public_api_id
  public_resource_id = module.api.public_resource_id
  public_method_http_method = module.api.public_method_http_method
  public_lambda_invoke_arn = module.lambda.public_invoke_arn
  public_lambda_function_name = module.lambda.public_function_name
  private_api_id = module.api.private_api_id
  private_resource_id = module.api.private_resource_id
  private_method_http_method = module.api.private_method_http_method
  isolated_lambda_invoke_arn = module.lambda.isolated_invoke_arn
  isolated_lambda_function_name = module.lambda.isolated_function_name
  public_api_log_group_arn = module.api.public_api_log_group_arn
  private_api_log_group_arn = module.api.private_api_log_group_arn
  log_retention_days = var.log_retention_days
}

resource "aws_s3_bucket_policy" "sensitive_data" {
  bucket = module.storage.bucket_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [module.storage.bucket_arn, "${module.storage.bucket_arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
      {
        Sid       = "AllowIsolatedLambdaObjectWrites"
        Effect    = "Allow"
        Principal = { AWS = module.lambda.isolated_role_arn }
        Action    = ["s3:PutObject"]
        Resource  = ["${module.storage.bucket_arn}/processed/*"]
      }
    ]
  })
}

module "waf" {
  source = "../../modules/waf"
  name   = local.common_name
  public_api_stage_arn = module.api_integration.public_stage_arn
  rate_limit = var.public_api_rate_limit
}
