terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ──────────────────────────────────────────────
# Variables
# ──────────────────────────────────────────────

variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

# ──────────────────────────────────────────────
# ECR Module (shared across environments)
# ──────────────────────────────────────────────

module "ecr" {
  source = "../../modules/ecr"

  repository_names = [
    "ecom-shop/user-service",
    "ecom-shop/product-service",
    "ecom-shop/shopping-cart-service",
  ]

  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
  max_image_count      = 30
}
