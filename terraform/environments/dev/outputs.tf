# ──────────────────────────────────────────────
# Outputs — Dev Environment
# ──────────────────────────────────────────────

# VPC
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

# EKS
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "update_kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# RDS
output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds.db_endpoint
}

# Cognito
output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_app_client_id" {
  description = "Cognito App Client ID"
  value       = module.cognito.app_client_id
}

output "alb_auth_idp_cognito_annotation" {
  description = "JSON annotation for ALB Cognito auth (paste into Helm values)"
  value       = module.cognito.alb_auth_idp_cognito_annotation
}

# IRSA Role ARNs
output "irsa_user_service_role_arn" {
  description = "IRSA role ARN for user-service"
  value       = module.irsa_user_service.role_arn
}

output "irsa_product_service_role_arn" {
  description = "IRSA role ARN for product-service"
  value       = module.irsa_product_service.role_arn
}

output "irsa_shopping_cart_service_role_arn" {
  description = "IRSA role ARN for shopping-cart-service"
  value       = module.irsa_shopping_cart_service.role_arn
}

# ArgoCD
output "argocd_server_host" {
  description = "ArgoCD server hostname"
  value       = module.argocd.argocd_server_host
}
