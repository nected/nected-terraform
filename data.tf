data "azurerm_kubernetes_cluster" "k8s" {
  count               = local.is_azure ? 1 : 0
  name                = module.azure_infra[0].aks_cluster_name
  resource_group_name = var.az_resource_group_name
  depends_on          = [module.azure_infra]
}

data "aws_eks_cluster" "this" {
  count      = local.is_aws ? 1 : 0
  name       = module.aws_infra[0].eks_cluster_name
  depends_on = [module.aws_infra]
}

data "aws_eks_cluster_auth" "this" {
  count      = local.is_aws ? 1 : 0
  name       = module.aws_infra[0].eks_cluster_name
  depends_on = [module.aws_infra]
}