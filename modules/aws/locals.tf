locals {
  vpc_id             = var.existing_vpc_id == "null" ? module.vpc[0].vpc_id : var.existing_vpc_id
  private_subnets    = var.existing_vpc_id == "null" ? module.vpc[0].private_subnets : var.existing_private_subnets
  database_subnets   = var.existing_vpc_id == "null" ? module.vpc[0].database_subnets : var.existing_database_subnets
  public_subnets     = var.existing_vpc_id == "null" ? module.vpc[0].public_subnets : var.existing_public_subnets
  opensearch_subnets = var.opensearch_multi_az_enabled ? local.database_subnets : [local.database_subnets[0]]

  cache_tls_enabled = var.use_managed_redis ? "true" : "false"
  cache_endpoint    = var.use_managed_redis ? module.valkey[0].replication_group_primary_endpoint_address : "datastore-redis-master"
  cache_port        = var.use_managed_redis ? module.valkey[0].replication_group_port : "6379"

}