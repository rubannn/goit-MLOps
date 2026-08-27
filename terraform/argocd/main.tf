data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket  = "mlops-tfstate-goit-512523811086"
    key     = "eks/terraform.tfstate"
    region  = "us-east-1"
    profile = "goit-terraform"
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    file("${path.module}/values/argocd-values.yaml")
  ]
}
