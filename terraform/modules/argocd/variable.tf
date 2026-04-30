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
