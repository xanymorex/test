data "aws_vpc_endpoint_service" "s3" {
  service      = "s3"
  service_type = "Gateway"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = data.aws_vpc_endpoint_service.s3.service_name
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(var.private_route_table_ids, var.isolated_route_table_ids)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowS3AccessFromVPC"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      Resource  = ["*"]
    }]
  })
  tags = { Name = "${var.name}-s3-gateway" }
}

resource "aws_vpc_endpoint" "execute_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.execute-api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.isolated_subnet_ids
  security_group_ids  = [var.endpoint_security_group_id]
  private_dns_enabled = true
  tags = { Name = "${var.name}-execute-api" }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.isolated_subnet_ids
  security_group_ids  = [var.endpoint_security_group_id]
  private_dns_enabled = true
  tags = { Name = "${var.name}-logs" }
}

output "execute_api_vpce_id" {
  value = aws_vpc_endpoint.execute_api.id
}
