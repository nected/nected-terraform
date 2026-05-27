#######################
# aws_lbc
#######################
resource "aws_iam_role" "aws_lbc" {
  name               = "${var.eks_cluster_name}-aws-lbc-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.aws_pod_identity_trust_policy.json
  #assume_role_policy = data.aws_iam_policy_document.aws_lbc_assume_role_policy.json
}

resource "aws_iam_policy" "aws_lbc" {
  policy = file("${path.module}/iam/lbc.json")
  name   = "AWSLoadBalancerController-${var.environment}"
}

resource "aws_iam_role_policy_attachment" "aws_lbc" {
  policy_arn = aws_iam_policy.aws_lbc.arn
  role       = aws_iam_role.aws_lbc.name
}

resource "aws_eks_pod_identity_association" "aws_lbc" {
  cluster_name    = var.eks_cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_lbc.arn
}

resource "helm_release" "aws_lbc" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.17.0"

  set = [
    {
      name  = "clusterName"
      value = var.eks_cluster_name
    },
    {
      name  = "podIdentity.enabled"
      value = "true"
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "vpcId"
      value = var.vpc_id
    }
  ]
}