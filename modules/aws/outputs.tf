output "opensearch_domain_endpoint" {
  value = module.opensearch.domain_endpoint
}

output "eks_cluster_oidc_issuer_url" {
  value = module.eks_cluster.cluster_oidc_issuer_url
}

output "eks_oidc_provider" {
  value = module.eks_cluster.oidc_provider
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