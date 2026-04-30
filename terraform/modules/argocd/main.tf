# ──────────────────────────────────────────────
# ArgoCD Namespace
# ──────────────────────────────────────────────

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace

    labels = {
      name        = var.argocd_namespace
      environment = var.env
    }
  }
}

# ──────────────────────────────────────────────
# ArgoCD via Helm
# Access via: kubectl port-forward svc/argocd-server -n argocd 8080:443
# ──────────────────────────────────────────────

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Ingress disabled — use kubectl port-forward instead
  set {
    name  = "server.ingress.enabled"
    value = "false"
  }

  # Run server in insecure mode (no self-signed cert issues with port-forward)
  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }

  depends_on = [kubernetes_namespace.argocd]
}
