provider "helm" {
  kubernetes = {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
    token                  = var.cluster_token
  }
}

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