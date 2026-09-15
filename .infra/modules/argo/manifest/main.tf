resource "kubernetes_manifest" "auth-service" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "${var.service_name}-service"
      namespace = "argocd"
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
    }
    spec = {
      project = "Togglemaster"
      source = {
        repoURL        = "https://github.com/Jffreitas-poli/fiap-pos-cloud-togglemaster.git"
        targetRevision = "main"
        path           = ".k8s/${var.service_name}-service"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.service_name
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }
}