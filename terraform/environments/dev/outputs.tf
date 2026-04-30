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

output "external_secrets_role_arn" {
  description = "IRSA role ARN for External Secrets Operator"
  value       = module.external_secrets.external_secrets_role_arn
}

output "cluster_secret_store_name" {
  description = "ClusterSecretStore used by workloads"
  value       = module.external_secrets.cluster_secret_store_name
}

# CloudFront
output "cloudfront_domain_name" {
  description = "CloudFront domain — use as CNAME target for shop-dev in Cloudflare"
  value       = var.acm_certificate_arn_us_east_1 != "" ? module.cloudfront_frontend[0].cloudfront_domain_name : "Not deployed (set acm_certificate_arn_us_east_1)"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation in CI/CD)"
  value       = var.acm_certificate_arn_us_east_1 != "" ? module.cloudfront_frontend[0].cloudfront_distribution_id : ""
}
