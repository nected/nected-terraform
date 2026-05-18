# Azure Config
provider "azurerm" {
  features {}
  subscription_id = var.az_subscription_id
}

provider "helm" {
  kubernetes = {
    host                   = local.k8s_host
    client_certificate     = base64decode(local.k8s_client_certificate)
    client_key             = base64decode(local.k8s_client_key)
    cluster_ca_certificate = base64decode(local.k8s_cluster_ca_certificate)
  }
  alias = "aks"
}

# AWS Config
provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.this[0].endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this[0].certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this[0].token
  }

  alias = "eks"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}