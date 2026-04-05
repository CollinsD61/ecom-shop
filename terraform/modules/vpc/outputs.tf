# ID VPC
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

# CIDR VPC
output "vpc_cidr_block" {
  description = "CIDR of VPC"
  value       = aws_vpc.this.cidr_block
}

# ID public subnet
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

# ID private subnet
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

# ID NAT Gateway
output "nat_gateway_ids" {
  description = "List of NAT gateway public IPs"
  value       = aws_eip.nat[*].public_ip
}

