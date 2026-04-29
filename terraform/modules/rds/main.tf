# ──────────────────────────────────────────────
# DB Subnet Group
# ──────────────────────────────────────────────

resource "aws_db_subnet_group" "this" {
  name       = "${var.env}-ecom-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.env}-ecom-db-subnet-group"
    Environment = var.env
  }
}

# ──────────────────────────────────────────────
# Security Group for RDS
# ──────────────────────────────────────────────

resource "aws_security_group" "rds" {
  name_prefix = "${var.env}-rds-sg-"
  description = "Security group for RDS PostgreSQL - ${var.env}"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.env}-rds-sg"
    Environment = var.env
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Allow inbound PostgreSQL from VPC CIDR (EKS pods)
resource "aws_security_group_rule" "rds_ingress_vpc" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr_block]
  security_group_id = aws_security_group.rds.id
  description       = "Allow PostgreSQL access from VPC"
}

# Allow inbound from EKS cluster security group
resource "aws_security_group_rule" "rds_ingress_eks" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.eks_security_group_id
  security_group_id        = aws_security_group.rds.id
  description              = "Allow PostgreSQL access from EKS cluster"
}

resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
}

# ──────────────────────────────────────────────
# RDS PostgreSQL Instance
# ──────────────────────────────────────────────

resource "aws_db_instance" "this" {
  identifier = "${var.env}-ecom-postgres"

  engine         = "postgres"
  engine_version = "16.13"
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  multi_az               = var.db_multi_az
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = var.db_backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  skip_final_snapshot       = var.db_skip_final_snapshot
  final_snapshot_identifier = var.db_skip_final_snapshot ? null : "${var.env}-ecom-postgres-final-snapshot"

  deletion_protection = var.env == "prod" ? true : false
  publicly_accessible = false

  tags = {
    Name        = "${var.env}-ecom-postgres"
    Environment = var.env
  }
}
