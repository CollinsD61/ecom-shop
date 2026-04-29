terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# ──────────────────────────────────────────────
# Variables
# ──────────────────────────────────────────────

variable "env" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}

variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type    = string
  default = "1.29"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t2.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 1
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 2
}

variable "node_disk_size" {
  type    = number
  default = 20
}

variable "db_name" {
  type    = string
  default = "ecomdb"
}

variable "db_username" {
  type    = string
  default = "ecomadmin"
}

resource "random_password" "rds_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_multi_az" {
  type    = bool
  default = false
}

variable "db_backup_retention_period" {
  type    = number
  default = 1
}

variable "db_skip_final_snapshot" {
  type    = bool
  default = true
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "domain_name" {
  type    = string
  default = "dohoangdevops.io.vn"
}

# ──────────────────────────────────────────────
# Providers
# ──────────────────────────────────────────────

provider "aws" {
  region = var.aws_region
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
  }
}

# ──────────────────────────────────────────────
# Data
# ──────────────────────────────────────────────

data "aws_caller_identity" "current" {}

# ──────────────────────────────────────────────
# Module: VPC
# ──────────────────────────────────────────────

module "vpc" {
  source = "../../modules/vpc"

  env                  = var.env
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# ──────────────────────────────────────────────
# Module: EKS
# ──────────────────────────────────────────────

module "eks" {
  source = "../../modules/eks"

  env                 = var.env
  cluster_name        = var.cluster_name
  cluster_version     = var.cluster_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_disk_size      = var.node_disk_size
}

# ──────────────────────────────────────────────
# Module: RDS
# ──────────────────────────────────────────────

module "rds" {
  source = "../../modules/rds"

  env                        = var.env
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  vpc_cidr_block             = module.vpc.vpc_cidr_block
  eks_security_group_id      = module.eks.cluster_security_group_id
  db_name                    = var.db_name
  db_username                = var.db_username
  db_password                = random_password.rds_password.result
  db_instance_class          = var.db_instance_class
  db_allocated_storage       = var.db_allocated_storage
  db_multi_az                = var.db_multi_az
  db_backup_retention_period = var.db_backup_retention_period
  db_skip_final_snapshot     = var.db_skip_final_snapshot
}

# ──────────────────────────────────────────────
# Module: ALB Controller
# ──────────────────────────────────────────────

module "alb_controller" {
  source = "../../modules/alb_controller"

  env               = var.env
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  vpc_id            = module.vpc.vpc_id
  aws_region        = var.aws_region
}

# ──────────────────────────────────────────────
# Module: External DNS
# ──────────────────────────────────────────────

module "external_dns" {
  source = "../../modules/external_dns"

  env                  = var.env
  cluster_name         = module.eks.cluster_name
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_provider_url    = module.eks.oidc_provider_url
  cloudflare_api_token = var.cloudflare_api_token
  domain_name          = var.domain_name
}

# ──────────────────────────────────────────────
# Module: ArgoCD
# ──────────────────────────────────────────────

module "argocd" {
  source = "../../modules/argocd"

  env                 = var.env
  cluster_name        = module.eks.cluster_name
  server_ingress_host = "argocd.${var.domain_name}"

  depends_on = [module.alb_controller]
}



# ──────────────────────────────────────────────
# Module: Secrets Manager
# ──────────────────────────────────────────────

module "secrets" {
  source = "../../modules/secrets"

  env         = var.env
  db_host     = module.rds.db_address
  db_port     = module.rds.db_port
  db_name     = module.rds.db_name
  db_username = var.db_username
  db_password = random_password.rds_password.result
}

# ──────────────────────────────────────────────
# Module: IRSA — user-service
# ──────────────────────────────────────────────

module "irsa_user_service" {
  source = "../../modules/irsa"

  env                  = var.env
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_provider_url    = module.eks.oidc_provider_url
  service_name         = "user-service"
  service_account_name = "sa-user-service"
  secret_arns = [
    module.secrets.service_db_secret_arns["user-service"],
    module.secrets.shared_rds_secret_arn,
  ]
}

# ──────────────────────────────────────────────
# Module: IRSA — product-service
# ──────────────────────────────────────────────

module "irsa_product_service" {
  source = "../../modules/irsa"

  env                  = var.env
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_provider_url    = module.eks.oidc_provider_url
  service_name         = "product-service"
  service_account_name = "sa-product-service"
  secret_arns = [
    module.secrets.service_db_secret_arns["product-service"],
    module.secrets.shared_rds_secret_arn,
  ]
}

# ──────────────────────────────────────────────
# Module: IRSA — shopping-cart-service
# ──────────────────────────────────────────────

module "irsa_shopping_cart_service" {
  source = "../../modules/irsa"

  env                  = var.env
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_provider_url    = module.eks.oidc_provider_url
  service_name         = "shopping-cart-service"
  service_account_name = "sa-shopping-cart-service"
  secret_arns = [
    module.secrets.service_db_secret_arns["shopping-cart-service"],
    module.secrets.shared_rds_secret_arn,
  ]
}
