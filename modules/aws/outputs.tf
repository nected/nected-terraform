output "opensearch_domain_endpoint" {
  value = module.opensearch.domain_endpoint
}

output "eks_cluster_oidc_issuer_url" {
  value = module.eks_cluster.cluster_oidc_issuer_url
}

output "eks_oidc_provider" {
  value = module.eks_cluster.oidc_provider
}

output "eks_oidc_provider_arn" {
  value = module.eks_cluster.oidc_provider_arn
}

output "eks_cluster_certificate_authority_data" {
  value = module.eks_cluster.cluster_certificate_authority_data
}

output "eks_cluster_name" {
  value = module.eks_cluster.cluster_name
}

output "vpc_id" {
  value = var.existing_vpc_id == "null" ? module.vpc[0].vpc_id : var.existing_vpc_id
}

output "private_subnets" {
  value = local.private_subnets
}

output "public_subnets" {
  value = local.public_subnets
}

output "rds_endpoint" {
  value = module.postgres.db_instance_address
}

output "rds_password" {
  value     = var.db_password
  sensitive = true
}

output "rds_port" {
  value = module.postgres.db_instance_port
}

output "cache_endpoint" {
  value = local.cache_endpoint
}

output "cache_port" {
  value = local.cache_port
}

output "cache_auth_token" {
  value     = var.valkey_auth_token
  sensitive = true
}

output "cache_tls_enabled" {
  value = local.cache_tls_enabled
}


output "alb_sg" {
  value = aws_security_group.alb.id
}

output "target_group_arns" {
  value = { for k, tg in aws_lb_target_group.this : k => tg.arn }
}

output "seed_node_ips" {
  value = local.seed_node_ips
}

output "alerts_sns_topic_arn" {
  value       = var.enable_cloudwatch_logging ? aws_sns_topic.alerts[0].arn : null
  description = "SNS topic ARN for CloudWatch alarms"
}

output "app_log_group_name" {
  value       = var.enable_cloudwatch_logging ? aws_cloudwatch_log_group.container_insights["application"].name : null
  description = "Container Insights application log group"
}