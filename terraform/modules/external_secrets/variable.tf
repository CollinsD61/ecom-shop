variable "env" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "aws_region" {
  type        = string
  description = "AWS region for Secrets Manager"
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS OIDC provider"
}

variable "oidc_provider_url" {
  type        = string
  description = "URL of the EKS OIDC provider (without https://)"
}

variable "secret_arns" {
  type        = list(string)
  description = "List of Secrets Manager ARNs that External Secrets Operator can read"
}

variable "namespace" {
  type        = string
  description = "Namespace to deploy External Secrets Operator"
  default     = "external-secrets"
}

variable "service_account_name" {
  type        = string
  description = "Service account name for External Secrets Operator"
  default     = "external-secrets"
}

variable "cluster_secret_store_name" {
  type        = string
  description = "ClusterSecretStore name used by applications"
  default     = "aws-secretsmanager"
}

variable "chart_version" {
  type        = string
  description = "Helm chart version for External Secrets Operator"
  default     = "1.3.2"
}
