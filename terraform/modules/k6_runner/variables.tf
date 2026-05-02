variable "env" {
  type        = string
  description = "Environment name (dev, prod, ...)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to place the k6 runner"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for the k6 EC2 instance (recommend public subnet)"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.small"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name for SSH access (optional — can use SSM instead)"
  default     = ""
}

variable "allowed_ssh_cidr" {
  type        = list(string)
  description = "CIDRs allowed to SSH into the k6 runner (leave empty to disable SSH port)"
  default     = []
}

variable "associate_public_ip" {
  type        = bool
  description = "Assign public IP (required for SSM without VPC endpoints)"
  default     = true
}
