variable "env" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS OIDC provider"
}

variable "oidc_provider_url" {
  type        = string
  description = "URL of the EKS OIDC provider (without https://)"
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token for DNS management"
  sensitive   = true
}

variable "domain_name" {
  type        = string
  description = "Domain name managed by Cloudflare"
  default     = "dohoangdevops.io.vn"
}

variable "chart_version" {
  type        = string
  description = "Helm chart version for External DNS"
  default     = "1.14.4"
}
