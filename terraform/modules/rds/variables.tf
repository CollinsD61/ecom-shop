variable "env" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for security group"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for DB subnet group"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR block for security group ingress"
}

variable "db_name" {
  type        = string
  description = "Name of the PostgreSQL database"
  default     = "ecomdb"
}

variable "db_username" {
  type        = string
  description = "Master username for the RDS instance"
  default     = "ecomadmin"
}

variable "db_password" {
  type        = string
  description = "Master password for the RDS instance"
  sensitive   = true
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  type        = number
  description = "Allocated storage in GB"
  default     = 20
}

variable "db_multi_az" {
  type        = bool
  description = "Enable Multi-AZ deployment"
  default     = false
}

variable "db_backup_retention_period" {
  type        = number
  description = "Number of days to retain backups"
  default     = 1
}

variable "db_skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot when deleting"
  default     = true
}

variable "eks_security_group_id" {
  type        = string
  description = "EKS cluster security group ID for inbound access"
}
