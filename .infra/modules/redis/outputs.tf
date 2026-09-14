output "redis_endpoint" { value = aws_elasticache_cluster.redis.cluster_address }
output "sg_id" {value = aws_security_group.sg_redis.id}
