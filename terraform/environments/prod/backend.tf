terraform {
  backend "s3" {
    bucket = "ecom-shop-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "ap-southeast-1"
  }
}
