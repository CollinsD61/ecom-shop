variable "env" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "chart_version" {
  type        = string
  description = "Helm chart version for ArgoCD"
  default     = "5.53.14"
}

variable "argocd_namespace" {
  type        = string
  description = "Kubernetes namespace for ArgoCD"
  default     = "argocd"
}

variable "server_ingress_enabled" {
  type        = bool
  description = "Enable ingress for ArgoCD server"
  default     = true
}

variable "server_ingress_host" {
  type        = string
  description = "Hostname for ArgoCD server ingress"
  default     = "argocd.dohoangdevops.io.vn"
}

variable "server_ingress_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for ArgoCD ingress HTTPS on ALB (leave empty to keep HTTP only)"
  default     = ""
}

variable "server_ingress_ssl_redirect" {
  type        = bool
  description = "Enable ALB HTTP->HTTPS redirect when certificate ARN is provided"
  default     = true
}
