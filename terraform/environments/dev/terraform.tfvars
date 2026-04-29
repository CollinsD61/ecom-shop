# ──────────────────────────────────────────────
# Dev Environment — terraform.tfvars
# ──────────────────────────────────────────────

env        = "dev"
aws_region = "ap-southeast-1"

# VPC
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
availability_zones   = ["ap-southeast-1a", "ap-southeast-1b"]

# EKS
cluster_name        = "dev-ecom-cluster"
cluster_version     = "1.29"
node_instance_types = ["t2.medium"]
node_desired_size   = 1
node_min_size       = 1
node_max_size       = 2
node_disk_size      = 20

# RDS
db_name                    = "ecomdb"
db_username                = "ecomadmin"
db_instance_class          = "db.t3.micro"
db_allocated_storage       = 20
db_multi_az                = false
db_backup_retention_period = 1
db_skip_final_snapshot     = true

# Domain
domain_name = "dohoangdevops.io.vn"
