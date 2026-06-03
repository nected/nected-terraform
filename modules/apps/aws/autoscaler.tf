###################
# cluster autoscaler
###################
resource "aws_iam_role" "cluster_autoscaler" {
  name               = "${var.eks_cluster_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.aws_pod_identity_trust_policy.json
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name   = "${var.eks_cluster_name}-cluster-autoscaler"
  policy = file("${path.module}/iam/autoscaler.json")
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
  role       = aws_iam_role.cluster_autoscaler.name
}

resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
  cluster_name    = var.eks_cluster_name
  namespace       = "kube-system"
  service_account = "cluster-autoscaler"
  role_arn        = aws_iam_role.cluster_autoscaler.arn
}

resource "helm_release" "cluster_autoscaler" {
  name = "autoscaler"

  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.57.0"

  set = [
    {
      name  = "rbac.serviceAccount.name"
      value = "cluster-autoscaler"
    },
    {
      name  = "autoDiscovery.clusterName"
      value = var.eks_cluster_name
    },
    {
      name  = "awsRegion"
      value = var.aws_region
    }
  ]

  depends_on = [
    helm_release.metrics_server,
  ]
}

