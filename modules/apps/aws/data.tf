data "aws_iam_policy_document" "aws_pod_identity_trust_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

# data "aws_iam_policy_document" "aws_lbc_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]

#     effect = "Allow"

#     principals {
#       type        = "Federated"
#       identifiers = [var.eks_oidc_provider_arn]
#     }

#     condition {
#       test     = "StringEquals"
#       variable = "${replace(var.eks_oidc_provider_url, "https://", "")}:sub"
#       values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
#     }
#   }
# }