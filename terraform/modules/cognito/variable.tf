variable "env" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "user_pool_name" {
  type        = string
  description = "Name of the Cognito User Pool"
  default     = "ecom-shop-users"
}

variable "callback_urls" {
  type        = list(string)
  description = "Allowed callback URLs after authentication"
  default     = ["https://ecom-shop.dohoangdevops.io.vn/oauth2/idpresponse"]
}

variable "logout_urls" {
  type        = list(string)
  description = "Allowed logout URLs"
  default     = ["https://ecom-shop.dohoangdevops.io.vn"]
}

variable "domain_prefix" {
  type        = string
  description = "Cognito domain prefix for hosted UI"
  default     = ""
}
