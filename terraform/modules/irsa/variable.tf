variable "env" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS OIDC provider"
}

variable "oidc_provider_url" {
  type        = string
  description = "URL of the EKS OIDC provider (without https://)"
}

variable "service_name" {
  type        = string
  description = "Name of the Kubernetes service (e.g., user-service)"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace for the service account"
  default     = "default"
}

variable "service_account_name" {
  type        = string
  description = "Name of the Kubernetes service account"
}

variable "secret_arns" {
  type        = list(string)
  description = "List of Secrets Manager ARNs this role can read"
}
