#######################
# nected-secret-sync
#
# IAM identity for the secret-manager hook that both the nected and temporal
# charts run as a pre-install/pre-upgrade job. It reads the application
# credentials out of Secrets Manager and writes them into a Kubernetes Secret.
#
# Uses EKS Pod Identity, matching the aws-lbc / autoscaler pattern in this
# module: the role is bound to (namespace, service account) server-side, so the
# chart needs no serviceAccount annotation.
#######################

resource "aws_iam_role" "secret_sync" {
  count = var.secret_manager.enabled ? 1 : 0

  name               = "${var.eks_cluster_name}-secret-sync-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.aws_pod_identity_trust_policy.json
}

# Read-only. The encryption-at-rest key is generated out of band and only read
# from here, so the job never needs write access to Secrets Manager.
data "aws_iam_policy_document" "secret_sync" {
  count = var.secret_manager.enabled ? 1 : 0

  statement {
    sid    = "ReadCredentials"
    effect = "Allow"

    # GetSecretValue alone. DescribeSecret was only needed by the existence
    # check behind the old backup, which 0.3.0 removed.
    actions = ["secretsmanager:GetSecretValue"]

    resources = var.secret_manager.secret_arns
  }

  dynamic "statement" {
    for_each = var.secret_manager.kms_key_arn == null ? [] : [var.secret_manager.kms_key_arn]

    content {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [statement.value]
    }
  }
}

resource "aws_iam_policy" "secret_sync" {
  count = var.secret_manager.enabled ? 1 : 0

  name   = "NectedSecretSync-${var.environment}"
  policy = data.aws_iam_policy_document.secret_sync[0].json
}

resource "aws_iam_role_policy_attachment" "secret_sync" {
  count = var.secret_manager.enabled ? 1 : 0

  policy_arn = aws_iam_policy.secret_sync[0].arn
  role       = aws_iam_role.secret_sync[0].name
}

resource "aws_eks_pod_identity_association" "secret_sync" {
  count = var.secret_manager.enabled ? 1 : 0

  cluster_name    = var.eks_cluster_name
  namespace       = var.secret_manager.namespace
  service_account = var.secret_manager.service_account_name
  role_arn        = aws_iam_role.secret_sync[0].arn
}
