variable "repository_names" {
  type        = list(string)
  description = "List of ECR repository names to create"
  default = [
    "ecom-shop/user-service",
    "ecom-shop/product-service",
    "ecom-shop/shopping-cart-service",
  ]
}

variable "image_tag_mutability" {
  type        = string
  description = "Tag mutability setting for the repository"
  default     = "MUTABLE"
}

variable "scan_on_push" {
  type        = bool
  description = "Enable image scanning on push"
  default     = true
}

variable "max_image_count" {
  type        = number
  description = "Maximum number of images to retain per repository"
  default     = 30
}
