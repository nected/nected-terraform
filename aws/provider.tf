# AWS Config
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "helm" {
  kubernetes = {
    host                   = local.eks_host
    cluster_ca_certificate = local.eks_ca_cert != "" ? base64decode(local.eks_ca_cert) : ""
    token                  = local.eks_auth_token
  }

  alias = "eks"
}