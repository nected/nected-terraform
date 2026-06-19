data "aws_iam_policy_document" "opensearch" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["es:ESHttp*"]

    resources = ["*"]
  }
}

data "aws_route53_zone" "primary" {
  count = var.route53_hosted_zone ? 1 : 0

  name = var.hosted_zone_domain
}