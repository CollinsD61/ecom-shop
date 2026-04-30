variable "env" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "domain_name" {
  type        = string
  description = "Root domain name (e.g., dohoangdevops.io.vn)"
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token for DNS validation record creation"
  sensitive   = true
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare Zone ID for the domain"
  default     = ""
}
