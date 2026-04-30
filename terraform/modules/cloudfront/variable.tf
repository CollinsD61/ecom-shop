variable "env" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "aws_region" {
  type        = string
  description = "AWS region where the S3 bucket is located"
  default     = "ap-southeast-1"
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket serving the frontend (e.g., shop-dev.dohoangdevops.io.vn)"
}

variable "domain_name" {
  type        = string
  description = "Frontend domain name (e.g., shop-dev.dohoangdevops.io.vn)"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN — MUST be in us-east-1 for CloudFront"
}
