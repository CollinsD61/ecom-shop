# ──────────────────────────────────────────────
# Cognito User Pool
# ──────────────────────────────────────────────

resource "aws_cognito_user_pool" "this" {
  name = "${var.env}-${var.user_pool_name}"

  # Username configuration
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  # Schema attributes
  schema {
    name                     = "email"
    attribute_data_type      = "String"
    required                 = true
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    name                     = "name"
    attribute_data_type      = "String"
    required                 = true
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = {
    Name        = "${var.env}-${var.user_pool_name}"
    Environment = var.env
  }
}

# ──────────────────────────────────────────────
# Cognito User Pool Domain (Hosted UI)
# ──────────────────────────────────────────────

locals {
  cognito_domain = var.domain_prefix != "" ? var.domain_prefix : "${var.env}-ecom-shop"
}

resource "aws_cognito_user_pool_domain" "this" {
  domain       = local.cognito_domain
  user_pool_id = aws_cognito_user_pool.this.id
}

# ──────────────────────────────────────────────
# Cognito App Client
# ──────────────────────────────────────────────

resource "aws_cognito_user_pool_client" "this" {
  name         = "${var.env}-ecom-app-client"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret = true

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  supported_identity_providers = ["COGNITO"]

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]
}
