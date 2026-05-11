module "azure" {
  source = "./modules/azure"

  count = local.is_azure ? 1 : 0

  # Core
  subscription_id     = var.az_subscription_id
  resource_group_name = var.az_resource_group_name

  # Project context
  project     = var.project
  environment = var.environment


  # DNS
  az_hosted_zone = var.az_hosted_zone
  base_domain    = var.base_domain
  hosted_zone_rg = var.az_hosted_zone_rg

  # AKS
  kubernetes_version          = var.k8s_version
  aks_node_count              = var.k8s_node_count
  aks_min_node_count          = var.k8s_min_node_count
  aks_max_node_count          = var.k8s_max_node_count
  aks_vm_size                 = var.k8s_vm_size
  aks_private_cluster_enabled = var.k8s_private_cluster_enabled


  pg_version          = var.pg_version
  pg_admin_user       = var.pg_admin_user
  pg_admin_passwd     = var.pg_admin_passwd
  pg_sku_name         = var.pg_sku_name
  pg_disk_size        = var.pg_disk_size
  pg_backup_retention = var.pg_backup_retention

  use_managed_redis = var.use_managed_redis
  redis_capacity    = var.redis_capacity


  elasticsearch_version         = var.elasticsearch_version
  elasticsearch_vm_size         = var.elasticsearch_vm_size
  elasticsearch_admin_username  = var.elasticsearch_admin_username
  elasticsearch_admin_password  = var.elasticsearch_admin_password
  elasticsearch_os_disk_size_gb = var.elasticsearch_os_disk_size_gb

  cassandra_node_count        = var.cassandra_node_count
  cassandra_vm_size           = var.cassandra_vm_size
  cassandra_admin_password    = var.cassandra_admin_password
  cassandra_admin_username    = var.cassandra_admin_username
  cassandra_data_disk_size_gb = var.cassandra_data_disk_size_gb

  # Networking
  vnet_address_space = var.network_address_space
  existing_vnet_name = var.existing_network_name
  existing_subnets   = var.existing_subnets
  private_subnets    = var.private_subnets

  agic_internal = var.agic_internal

  # Domain prefixes (used for ingress/DNS)
  ui_domain_prefix      = var.ui_domain_prefix
  backend_domain_prefix = var.backend_domain_prefix
  router_domain_prefix  = var.router_domain_prefix

  key_vault_name             = var.key_vault_name
  key_vault_certificate_name = var.key_vault_certificate_name
}

# module "aws" {
#   source = "./modules/aws"

#   count = local.is_aws ? 1 : 0
#   project             = "test"
#   eks_node_count      = var.k8s_node_count
#   eks_min_node_count  = var.k8s_min_node_count
#   eks_max_node_count  = var.k8s_max_node_count
# }



module "azure_agic" {
  source = "./modules/apps/azure"

  count = local.is_azure && var.app == true ? 1 : 0

  alb_vault_secret_endpoint      = module.azure[0].alb_vault_secret_endpoint
  backend_domain                 = local.backend_domain
  router_domain                  = local.router_domain
  ui_domain                      = local.ui_domain
  resource_group_location        = module.azure[0].resource_group_location
  resource_group_name            = var.az_resource_group_name
  environment                    = var.environment
  base_domain                    = var.base_domain
  namespace                      = var.namespace
  project                        = var.project
  key_vault_name                 = var.key_vault_name
  appgw_subnet_id                = module.azure[0].subnets["appgw"].id
  cert_secret_name               = module.azure[0].cert_secret_name
  cert_vault_name                = module.azure[0].cert_vault_name
  hosted_zone_rg                 = var.az_hosted_zone_rg
  console_user_email             = var.console_user_email
  subscription_id                = var.az_subscription_id
  identity_client_id             = module.azure[0].identity_client_id
  identity_principal_id          = module.azure[0].identity_principal_id
  aks_identity_principal_id      = module.azure[0].aks_identity_principal_id
  identity_id                    = module.azure[0].identity_id
  az_hosted_zone                 = var.az_hosted_zone
  public_app_gateway_id          = module.azure[0].public_app_gateway_id
  public_app_gateway_ip          = module.azure[0].public_app_gateway_ip
  internal_app_gateway_ip        = module.azure[0].internal_app_gateway_ip
  agic_ssl_certificate_identifer = local.agic_ssl_certificate_identifer
  agic_internal                  = var.agic_internal

  depends_on = [module.azure]
}


locals {
  agic_ssl_certificate_identifer = "${var.project}-ssl-certificate"
  elasticsearch_ip               = local.is_azure ? module.azure[0].elasticsearch_ip : ""
  seed_node_list                 = local.is_azure ? module.azure[0].cassandra_seed_node_list : []
  postgresql_host                = local.is_azure ? module.azure[0].postgresql_host : ""

  redis_tls_enabled = local.is_azure ? module.azure[0].redis_tls_enabled : ""
  redis_endpoint    = local.is_azure ? module.azure[0].redis_endpoint : ""
  redis_port        = local.is_azure ? module.azure[0].redis_port : ""
  redis_password    = local.is_azure ? module.azure[0].redis_password : ""

  az_ingress_annotations = {
    "kubernetes.io/ingress.class"                       = "azure/application-gateway"
    "appgw.ingress.kubernetes.io/ssl-redirect"          = "true"
    "appgw.ingress.kubernetes.io/use-private-ip"        = var.agic_internal ? "true" : "false"
    "appgw.ingress.kubernetes.io/appgw-ssl-certificate" = local.agic_ssl_certificate_identifer
  }

  aws_ingress_annotations = {}

  ingress_annotations = local.is_azure ? local.az_ingress_annotations : local.aws_ingress_annotations
}

module "nected_app" {
  source = "./modules/apps/common"

  count                        = local.is_azure && var.app == true ? 1 : 0
  elasticsearch_ip             = local.elasticsearch_ip
  elasticsearch_admin_username = var.elasticsearch_admin_username
  elasticsearch_admin_password = var.elasticsearch_admin_password
  backend_domain               = local.backend_domain
  router_domain                = local.router_domain
  ui_domain                    = local.ui_domain
  namespace                    = var.namespace

  pg_admin_user   = var.pg_admin_user
  pg_admin_passwd = var.pg_admin_passwd
  postgresql_host = local.postgresql_host

  temporal_pods_resources    = var.temporal_pods_resources
  temporal_pods_replicas     = var.temporal_pods_replicas
  temporal_task_partitions   = var.temporal_task_partitions
  temporal_history_shards    = var.temporal_history_shards
  temporal_persistant_driver = var.cassandra_node_count != 0 ? "cassandra" : "sql"

  nected_enable_garuda  = var.nected_enable_garuda
  nected_env_overrides  = var.nected_env_overrides
  nected_pods_replicas  = var.nected_pods_replicas
  nected_pods_resources = var.nected_pods_resources
  seed_node_list        = local.seed_node_list

  use_managed_redis           = var.use_managed_redis
  redis_endpoint              = local.redis_endpoint
  redis_password              = local.redis_password
  redis_port                  = local.redis_port
  redis_tls_enabled           = local.redis_tls_enabled
  console_user_email          = var.console_user_email
  console_user_password       = var.console_user_password
  nected_pre_shared_key       = var.nected_pre_shared_key
  ingress_annotations         = local.ingress_annotations
  nected_existing_secret_name = var.nected_existing_secret_name
  nected_common_secret_value  = var.nected_common_secret_value

  depends_on = [
    module.azure_agic,
    module.azure
  ]
}