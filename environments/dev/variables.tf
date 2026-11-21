variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "name_prefix" {
  description = "Prefix used for resource names."
  type        = string
  default     = "microservices"
}

variable "vpc_cidr" {
  description = "VPC IPv4 CIDR."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Exactly two AZ names. Empty means discover the first two available AZs."
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.availability_zones) == 0 || length(var.availability_zones) == 2
    error_message = "Specify either zero or exactly two availability zones."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention."
  type        = number
  default     = 30
}

variable "public_api_rate_limit" {
  description = "WAF rate limit per five-minute evaluation window."
  type        = number
  default     = 1000
}

variable "private_api_vpce_id_override" {
  description = "Optional pre-existing execute-api endpoint ID. Leave empty to use the endpoint created by this stack."
  type        = string
  default     = ""
}
