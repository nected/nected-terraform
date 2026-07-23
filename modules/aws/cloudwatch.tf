############################################################
# CloudWatch logging & alerting for EKS application logs
############################################################

locals {
  cw_enabled         = var.enable_cloudwatch_logging ? 1 : 0
  container_insights = "/aws/containerinsights/${var.project}-${var.environment}"
  app_log_group_name = "${local.container_insights}/application"
}

# -------------------
# Pod Identity role for the CloudWatch agent
# -------------------
data "aws_iam_policy_document" "cw_agent_trust" {
  count = local.cw_enabled

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cw_observability" {
  count              = local.cw_enabled
  name               = "${var.project}-${var.environment}-cw-observability"
  assume_role_policy = data.aws_iam_policy_document.cw_agent_trust[0].json

  tags = merge(var.tags, { Environment = var.environment })
}

resource "aws_iam_role_policy_attachment" "cw_observability" {
  count      = local.cw_enabled
  role       = aws_iam_role.cw_observability[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_eks_pod_identity_association" "cw_observability" {
  count           = local.cw_enabled
  cluster_name    = module.eks_cluster.cluster_name
  namespace       = "amazon-cloudwatch"
  service_account = "cloudwatch-agent"
  role_arn        = aws_iam_role.cw_observability[0].arn

  tags = merge(var.tags, { Environment = var.environment })
}

# -------------------
# Alerting: SNS topic + email subscriptions
# -------------------
resource "aws_sns_topic" "alerts" {
  count = local.cw_enabled
  name  = "${var.project}-${var.environment}-app-alerts"

  tags = merge(var.tags, { Environment = var.environment })
}

resource "aws_sns_topic_subscription" "alerts_email" {
  for_each = var.enable_cloudwatch_logging ? toset(var.alert_emails) : toset([])

  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = each.value
}

# -------------------
# Application error rate: log metric filter + alarm
# -------------------
resource "aws_cloudwatch_log_metric_filter" "app_errors" {
  count          = local.cw_enabled
  name           = "${var.project}-${var.environment}-app-errors"
  log_group_name = "/aws/containerinsights/${var.project}-${var.environment}/application"
  pattern        = var.app_error_log_pattern

  metric_transformation {
    name          = "AppErrorCount"
    namespace     = "Nected/${var.environment}"
    value         = "1"
    default_value = "0"
  }

  depends_on = [module.eks_cluster]
}

resource "aws_cloudwatch_metric_alarm" "app_error_rate" {
  count               = local.cw_enabled
  alarm_name          = "${var.project}-${var.environment}-high-app-errors"
  alarm_description   = "Application error log lines exceeded ${var.app_error_alarm_threshold} in ${var.app_error_alarm_period}s"
  namespace           = "Nected/${var.environment}"
  metric_name         = "AppErrorCount"
  statistic           = "Sum"
  period              = var.app_error_alarm_period
  evaluation_periods  = 1
  threshold           = var.app_error_alarm_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts[0].arn]
  ok_actions    = [aws_sns_topic.alerts[0].arn]

  tags = merge(var.tags, { Environment = var.environment })
}

# -------------------
# Container Insights infra alarms (fire before app errors show up)
# -------------------
resource "aws_cloudwatch_metric_alarm" "node_cpu_high" {
  count               = local.cw_enabled
  alarm_name          = "${var.project}-${var.environment}-node-cpu-high"
  alarm_description   = "EKS node CPU utilization above 85%"
  namespace           = "ContainerInsights"
  metric_name         = "node_cpu_utilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  threshold           = 85
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = "${var.project}-${var.environment}"
  }

  alarm_actions = [aws_sns_topic.alerts[0].arn]
  ok_actions    = [aws_sns_topic.alerts[0].arn]

  tags = merge(var.tags, { Environment = var.environment })
}

resource "aws_cloudwatch_metric_alarm" "node_memory_high" {
  count               = local.cw_enabled
  alarm_name          = "${var.project}-${var.environment}-node-memory-high"
  alarm_description   = "EKS node memory utilization above 85%"
  namespace           = "ContainerInsights"
  metric_name         = "node_memory_utilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  threshold           = 85
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = "${var.project}-${var.environment}"
  }

  alarm_actions = [aws_sns_topic.alerts[0].arn]
  ok_actions    = [aws_sns_topic.alerts[0].arn]

  tags = merge(var.tags, { Environment = var.environment })
}
