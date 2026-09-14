module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = ">= 1.16"

  cluster_name      = var.cluster_name
  cluster_endpoint  = var.cluster_endpoint
  cluster_version   = var.cluster_version
  oidc_provider_arn = var.oidc_provider_arn

  enable_argocd = true

  argocd = {
    name          = "argocd"
    chart_version = "5.53.0"
    repository    = "https://argoproj.github.io/argo-helm"
    namespace     = "argocd"
    
    # Custom values passed directly or via set
    set = [
      {
        name  = "server.service.type"
        value = "LoadBalancer"
      }
    ]
  }
}

resource "kubernetes_manifest" "argo" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "togglemaster"
      namespace = "argocd"
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/Jffreitas-poli/fiap-pos-cloud-togglemaster.git"
        targetRevision = "main"
        path           = ".kubernetes/overlays/production"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "toggle"
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