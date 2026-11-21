resource "aws_security_group" "public_lambda" {
  name        = "${var.name}-public-lambda"
  description = "Public API Lambda egress to private API endpoint and internet via NAT."
  vpc_id      = var.vpc_id

  egress {
    description = "HTTPS egress; destination restrictions are enforced by endpoint SG and routing."
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.name}-public-lambda-sg" }
}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.region}.s3"
}

resource "aws_security_group" "isolated_lambda" {
  name        = "${var.name}-isolated-lambda"
  description = "Isolated Lambda outbound only to S3 prefix list and Logs endpoint."
  vpc_id      = var.vpc_id
  tags        = { Name = "${var.name}-isolated-lambda-sg" }
}

resource "aws_security_group" "endpoints" {
  name        = "${var.name}-endpoints"
  description = "HTTPS ingress to interface endpoints from Lambda security groups."
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTPS from public Lambda"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.public_lambda.id]
  }

  egress {
    description = "Endpoint response traffic"
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = { Name = "${var.name}-endpoint-sg" }
}

resource "aws_vpc_security_group_egress_rule" "isolated_logs" {
  security_group_id            = aws_security_group.isolated_lambda.id
  referenced_security_group_id = aws_security_group.endpoints.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "CloudWatch Logs interface endpoint"
}

output "public_lambda_sg_id" {
  value = aws_security_group.public_lambda.id
}

output "isolated_lambda_sg_id" {
  value = aws_security_group.isolated_lambda.id
}

output "endpoint_sg_id" {
  value = aws_security_group.endpoints.id
}


resource "aws_vpc_security_group_ingress_rule" "isolated_to_endpoint" {
  security_group_id            = aws_security_group.endpoints.id
  referenced_security_group_id = aws_security_group.isolated_lambda.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "HTTPS from isolated Lambda to CloudWatch Logs endpoint"
}

resource "aws_vpc_security_group_egress_rule" "isolated_s3" {
  security_group_id = aws_security_group.isolated_lambda.id
  prefix_list_id    = data.aws_prefix_list.s3.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS to S3 through the S3 Gateway Endpoint"
}
