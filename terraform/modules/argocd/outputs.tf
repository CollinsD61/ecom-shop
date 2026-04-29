output "argocd_namespace" {
  description = "Namespace where ArgoCD is deployed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_host" {
  description = "ArgoCD server ingress hostname"
  value       = var.server_ingress_host
}
