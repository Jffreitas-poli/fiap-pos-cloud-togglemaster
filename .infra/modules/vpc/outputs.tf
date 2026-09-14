output "vpc_id" { value = aws_vpc.vpc.id }
output "public_subnet_ids" { value = values(aws_subnet.sn_public)[*].id }
output "private_subnet_ids" { value = values(aws_subnet.sn_private)[*].id }
