data "aws_eks_cluster" "this" {
  name       = module.aws_infra.eks_cluster_name
  depends_on = [module.aws_infra]
}

data "aws_eks_cluster_auth" "this" {
  name       = module.aws_infra.eks_cluster_name
  depends_on = [module.aws_infra]
}