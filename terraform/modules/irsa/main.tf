# ──────────────────────────────────────────────
# IRSA — IAM Roles for Service Accounts
# Reusable module: 1 instance per microservice
# ──────────────────────────────────────────────

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.env}-${var.service_account_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name        = "${var.env}-${var.service_account_name}-role"
    Environment = var.env
    Service     = var.service_name
  }
}

# ──────────────────────────────────────────────
# Policy: Read Secrets Manager
# ──────────────────────────────────────────────

resource "aws_iam_policy" "secrets_read" {
  name        = "${var.env}-${var.service_name}-secrets-read"
  description = "Allow ${var.service_name} to read its Secrets Manager entries"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.secret_arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_read" {
  policy_arn = aws_iam_policy.secrets_read.arn
  role       = aws_iam_role.this.name
}
