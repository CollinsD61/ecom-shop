# ──────────────────────────────────────────────
# Prod Environment — terraform.tfvars
# ──────────────────────────────────────────────

env        = "prod"
aws_region = "ap-southeast-1"

# VPC
vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.20.0/24"]
availability_zones   = ["ap-southeast-1a", "ap-southeast-1b"]

# EKS
cluster_name        = "prod-ecom-cluster"
cluster_version     = "1.29"
node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 2
node_max_size       = 3
node_disk_size      = 30

# RDS
db_name                    = "ecomdb"
db_username                = "ecomadmin"
db_password                = "ProdPassword123!CHANGE_ME"
db_instance_class          = "db.t3.small"
db_allocated_storage       = 50
db_multi_az                = true
db_backup_retention_period = 7
db_skip_final_snapshot     = false

# Domain
domain_name = "dohoangdevops.io.vn"
