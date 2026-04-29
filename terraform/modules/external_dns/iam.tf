# ──────────────────────────────────────────────
# IAM Role for External DNS (IRSA)
# ──────────────────────────────────────────────

data "aws_iam_policy_document" "external_dns_assume_role" {
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
      values   = ["system:serviceaccount:kube-system:external-dns"]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_dns" {
  name               = "${var.env}-external-dns-role"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role.json

  tags = {
    Name        = "${var.env}-external-dns-role"
    Environment = var.env
  }
}

# External DNS needs Route53 permissions for AWS DNS mode
# For Cloudflare mode, the Cloudflare API token is passed via Helm values
resource "aws_iam_policy" "external_dns" {
  name        = "${var.env}-ExternalDNSPolicy"
  description = "IAM policy for External DNS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  policy_arn = aws_iam_policy.external_dns.arn
  role       = aws_iam_role.external_dns.name
}
