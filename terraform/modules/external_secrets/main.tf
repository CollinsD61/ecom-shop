# ──────────────────────────────────────────────
# External Secrets Operator Namespace
# ──────────────────────────────────────────────

resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = var.namespace

    labels = {
      name        = var.namespace
      environment = var.env
    }
  }
}

# ──────────────────────────────────────────────
# IRSA for External Secrets Operator
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

resource "aws_iam_role" "external_secrets" {
  name               = "${var.env}-external-secrets-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name        = "${var.env}-external-secrets-role"
    Environment = var.env
    Service     = "external-secrets"
  }
}

resource "aws_iam_policy" "secrets_read" {
  name        = "${var.env}-external-secrets-read"
  description = "Allow External Secrets Operator to read required Secrets Manager entries"

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
  role       = aws_iam_role.external_secrets.name
}

# ──────────────────────────────────────────────
# External Secrets Operator via Helm
# ──────────────────────────────────────────────

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = var.chart_version
  namespace  = kubernetes_namespace.external_secrets.metadata[0].name

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "crds.unsafeServeV1Beta1"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = var.service_account_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_secrets.arn
  }

  depends_on = [
    aws_iam_role_policy_attachment.secrets_read,
  ]
}

# ──────────────────────────────────────────────
# Shared ClusterSecretStore (aws-secretsmanager)
# ──────────────────────────────────────────────

resource "kubernetes_manifest" "cluster_secret_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = var.cluster_secret_store_name
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = var.aws_region
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = var.service_account_name
                namespace = var.namespace
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.external_secrets]
}
