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
    host                   = local.eks_host
    cluster_ca_certificate = local.eks_ca_cert != "" ? base64decode(local.eks_ca_cert) : ""
    token                  = local.eks_auth_token
  }

  alias = "eks"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}