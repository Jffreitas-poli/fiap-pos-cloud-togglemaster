# Subnet group para o Redis nas sub-redes privadas
resource "aws_elasticache_subnet_group" "sng_redis" {
  name        = "tc-${var.env}-sng-redis"
  description = "Redis access"
  subnet_ids  = var.private_subnet_ids
  tags        = { Name = "tc-${var.env}-sng-redis" }
}

# SG restrito para o Redis
resource "aws_security_group" "sg_redis" {
  name        = "tc-${var.env}-sg-redis"
  description = "Redis access"
  vpc_id      = var.vpc_id

  tags = { Name = "tc-${var.env}-sg-redis" }
}

resource "aws_vpc_security_group_egress_rule" "sgr_egress_redis" {
  security_group_id = aws_security_group.sg_redis.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "tc-${var.env}-redis"
  engine               = "redis"
  engine_version       = "7.1"
  port                 = 6379
  parameter_group_name = "default.redis7"
  num_cache_nodes      = 1
  node_type            = "cache.t3.micro"
  security_group_ids   = [aws_security_group.sg_redis.id]
  subnet_group_name    = aws_elasticache_subnet_group.sng_redis.name
}
