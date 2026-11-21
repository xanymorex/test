terraform {
  required_version = ">= 1.11.0"

  cloud {
    organization = "REPLACE_WITH_TFC_ORGANIZATION"

    workspaces {
      name = "aws-microservices-dev"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.name_prefix
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
