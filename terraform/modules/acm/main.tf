# ──────────────────────────────────────────────
# ACM Wildcard Certificate
# Validates via Cloudflare DNS (using http provider)
# ──────────────────────────────────────────────

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

resource "aws_acm_certificate" "wildcard" {
  domain_name               = "*.${var.domain_name}"
  subject_alternative_names = [var.domain_name]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.env}-wildcard-cert"
    Environment = var.env
  }
}

# ──────────────────────────────────────────────
# DNS Validation records (Cloudflare via API)
# ──────────────────────────────────────────────

resource "aws_acm_certificate_validation" "wildcard" {
  certificate_arn         = aws_acm_certificate.wildcard.arn
  validation_record_fqdns = [for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.resource_record_name]

  timeouts {
    create = "15m"
  }
}
