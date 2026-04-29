terraform {
  backend "s3" {
    bucket = "ecom-shop-terraform-state"
    key    = "shared/terraform.tfstate"
    region = "ap-southeast-1"
  }
}
