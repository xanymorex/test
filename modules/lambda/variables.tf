variable "name" { type = string }
variable "region" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "isolated_subnet_ids" { type = list(string) }
variable "public_lambda_sg_id" { type = string }
variable "isolated_lambda_sg_id" { type = string }
variable "log_retention_days" { type = number }
variable "private_api_url" { type = string }
variable "private_api_execution_arn" { type = string }
variable "s3_bucket_arn" { type = string }
variable "kms_key_arn" { type = string }

variable "s3_bucket_name" { type = string }
