variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for public subnets"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks for private subnets"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones for the subnets"
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Whether to create a NAT Gateway for private subnets"
  default     = false
}

variable "env" {
  type        = string
  description = "Environment name (e.g., dev, staging, prod)"
}
