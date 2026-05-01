variable "env" {
  type        = string
  description = "Environment name (dev, prod, etc.)"
}

variable "cluster_name" {
  type        = string
  description = "EKS Cluster Name"
}

variable "datadog_api_key" {
  type        = string
  description = "Datadog API Key"
  sensitive   = true
}

variable "datadog_site" {
  type        = string
  description = "Datadog Site (e.g. us5.datadoghq.com)"
  default     = "us5.datadoghq.com"
}
