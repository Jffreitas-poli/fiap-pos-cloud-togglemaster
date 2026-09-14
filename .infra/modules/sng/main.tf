# Subnet group para o RDS nas sub-redes privadas
resource "aws_db_subnet_group" "sng_rds" {
  name        = "tc-${var.env}-sng-rds"
  description = "RDS access"
  subnet_ids  = var.private_subnet_ids
  tags        = { Name = "tc-${var.env}-sng-rds" }
}

# SG restrito para o RDS
resource "aws_security_group" "sg_rds" {
  name        = "tc-${var.env}-sg-rds"
  description = "RDS access"
  vpc_id      = var.vpc_id
  tags        = { Name = "tc-${var.env}-sg-rds" }
}

resource "aws_vpc_security_group_egress_rule" "sgr_egress_rds" {
  security_group_id = aws_security_group.sg_rds.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}