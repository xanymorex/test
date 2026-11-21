data "aws_caller_identity" "current" {}

resource "aws_kms_key" "data" {
  description             = "KMS key for ${var.name} sensitive data bucket"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags = { Name = "${var.name}-data-key" }
}

resource "aws_kms_alias" "data" {
  name          = "alias/${var.name}-data"
  target_key_id = aws_kms_key.data.key_id
}

resource "aws_s3_bucket" "data" {
  bucket_prefix = "${var.name}-sensitive-"
  force_destroy = false
  tags = { Name = "${var.name}-sensitive-data" }
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.data.arn
    }
    bucket_key_enabled = true
  }
}



resource "aws_kms_key_policy" "data" {
  key_id = aws_kms_key.data.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableAccountIAMPermissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      }
    ]
  })
}

output "bucket_name" { value = aws_s3_bucket.data.bucket }
output "bucket_arn" { value = aws_s3_bucket.data.arn }
output "kms_key_arn" { value = aws_kms_key.data.arn }
