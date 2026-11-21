output "vpc_id" {
  value       = module.networking.vpc_id
  description = "VPC ID."
}

output "public_api_url" {
  value       = module.api.public_api_url
  description = "Public Regional REST API URL."
}

output "private_api_id" {
  value       = module.api.private_api_id
  description = "Private REST API ID."
}

output "private_api_url" {
  value       = module.api.private_api_url
  description = "Private API URL, resolvable from inside the VPC."
}

output "s3_bucket_name" {
  value       = module.storage.bucket_name
  description = "Sensitive data bucket name."
}

output "execute_api_vpce_id" {
  value       = module.endpoints.execute_api_vpce_id
  description = "execute-api Interface VPC Endpoint ID."
}
