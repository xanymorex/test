variable "name" { type = string }
variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "region" { type = string }
variable "private_route_table_ids" { type = list(string) }
variable "isolated_route_table_ids" { type = list(string) }
variable "isolated_subnet_ids" { type = list(string) }
variable "endpoint_security_group_id" { type = string }
