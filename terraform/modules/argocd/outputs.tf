output "argocd_namespace" {
  description = "Namespace where ArgoCD is deployed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_port_forward_cmd" {
  description = "Command to access ArgoCD UI locally"
  value       = "kubectl port-forward svc/argocd-server -n argocd 8080:443"
}
