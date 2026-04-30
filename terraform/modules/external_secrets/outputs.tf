output "external_secrets_role_arn" {
  description = "IAM role ARN for External Secrets Operator"
  value       = aws_iam_role.external_secrets.arn
}

output "cluster_secret_store_name" {
  description = "ClusterSecretStore name created for workloads"
  value       = var.cluster_secret_store_name
}
