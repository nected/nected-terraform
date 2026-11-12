data "aws_eks_cluster" "this" {
  name       = module.aws_infra.eks_cluster_name
  depends_on = [module.aws_infra]
}

data "aws_eks_cluster_auth" "this" {
  name       = module.aws_infra.eks_cluster_name
  depends_on = [module.aws_infra]
}
# Needed to build the encryption-at-rest secret ARN pattern: the item is
# created by an operator, not by terraform, so there is no resource to
# reference.
data "aws_caller_identity" "current" {}
