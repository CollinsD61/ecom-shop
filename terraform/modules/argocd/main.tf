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
# ──────────────────────────────────────────────

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Server configuration
  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  # Ingress for ArgoCD UI via ALB
  set {
    name  = "server.ingress.enabled"
    value = tostring(var.server_ingress_enabled)
  }

  set {
    name  = "server.ingress.ingressClassName"
    value = "alb"
  }

  set {
    name  = "server.ingress.hosts[0]"
    value = var.server_ingress_host
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
    value = "internet-facing"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
    value = "ip"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/listen-ports"
    value = "[{\"HTTP\": 80}]"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/healthcheck-path"
    value = "/healthz"
  }

  # Disable TLS on ArgoCD server (ALB handles TLS termination)
  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }

  depends_on = [kubernetes_namespace.argocd]
}
