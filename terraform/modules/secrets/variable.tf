variable "env" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "db_host" {
  type        = string
  description = "RDS hostname"
}

variable "db_port" {
  type        = number
  description = "RDS port"
  default     = 5432
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "db_username" {
  type        = string
  description = "Database master username"
}

variable "db_password" {
  type        = string
  description = "Database master password"
  sensitive   = true
}

variable "service_names" {
  type        = list(string)
  description = "List of service names that need DB secrets"
  default     = ["user-service", "product-service", "shopping-cart-service"]
}

variable "cognito_hosted_ui_login_url" {
  type        = string
  description = "Cognito hosted UI login URL"
  default     = ""
}

variable "cognito_hosted_ui_signup_url" {
  type        = string
  description = "Cognito hosted UI signup URL"
  default     = ""
}
