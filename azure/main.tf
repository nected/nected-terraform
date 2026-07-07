############ Azure Infra Setup #############
module "azure_infra" {
  source = "./../modules/azure"

  # Core
  subscription_id     = var.az_subscription_id
  resource_group_name = var.az_resource_group_name

  # Project context
  project     = var.project
  environment = var.environment

  # Networking
  vnet_address_space = var.network_address_space
  existing_vnet_name = var.az_existing_network_name
  existing_subnets   = var.az_existing_subnets
  private_subnets    = var.az_private_subnets

  allowed_gw_cidrs  = var.allowed_lb_cidrs
  allowed_aks_cidrs = var.allowed_k8s_cidrs

  # DNS
  az_hosted_zone = var.az_hosted_zone
  base_domain    = var.base_domain
  hosted_zone_rg = var.az_hosted_zone_rg
  agic_internal  = var.agic_internal

  # AKS
  kubernetes_version          = var.k8s_version
  aks_node_count              = var.k8s_node_count
  aks_min_node_count          = var.k8s_min_node_count
  aks_max_node_count          = var.k8s_max_node_count
  aks_vm_size                 = var.aks_vm_size
  aks_private_cluster_enabled = var.aks_private_cluster_enabled
  aks_zones                   = var.aks_zones

  # Postgresql
  pg_version          = var.pg_version
  pg_admin_user       = var.pg_admin_user
  pg_admin_passwd     = var.pg_admin_passwd
  pg_sku_name         = var.az_pg_sku_name
  pg_disk_size        = var.az_pg_disk_size
  pg_backup_retention = var.pg_backup_retention

  # Cache
  use_managed_redis = var.use_managed_cache
  redis_sku_name    = var.az_redis_sku

  # ElasticSearch
  elasticsearch_version         = var.elasticsearch_version
  elasticsearch_vm_size         = var.elasticsearch_vm_size
  elasticsearch_admin_username  = var.elasticsearch_admin_username
  elasticsearch_admin_password  = var.elasticsearch_admin_password
  elasticsearch_os_disk_size_gb = var.elasticsearch_os_disk_size_gb

  # Cassandra
  cassandra_node_count        = var.cassandra_node_count
  cassandra_vm_size           = var.az_cassandra_vm_size
  cassandra_admin_password    = var.cassandra_admin_password
  cassandra_admin_username    = var.cassandra_admin_username
  cassandra_data_disk_size_gb = var.cassandra_data_disk_size_gb

  # Domain prefixes (used for ingress/DNS)
  ui_domain_prefix      = var.ui_domain_prefix
  backend_domain_prefix = var.backend_domain_prefix
  router_domain_prefix  = var.router_domain_prefix

  key_vault_name             = var.az_key_vault_name
  key_vault_certificate_name = var.az_key_vault_certificate_name
}

module "azure_agic" {
  source = "./../modules/apps/azure"

  count = var.app == true ? 1 : 0

  alb_vault_secret_endpoint      = module.azure_infra.alb_vault_secret_endpoint
  backend_domain                 = local.backend_domain
  router_domain                  = local.router_domain
  ui_domain                      = local.ui_domain
  resource_group_location        = module.azure_infra.resource_group_location
  resource_group_name            = var.az_resource_group_name
  environment                    = var.environment
  base_domain                    = var.base_domain
  namespace                      = var.namespace
  project                        = var.project
  key_vault_name                 = var.az_key_vault_name
  appgw_subnet_id                = module.azure_infra.subnets["appgw"].id
  cert_secret_name               = module.azure_infra.cert_secret_name
  cert_vault_name                = module.azure_infra.cert_vault_name
  hosted_zone_rg                 = var.az_hosted_zone_rg
  console_user_email             = var.console_user_email
  subscription_id                = var.az_subscription_id
  identity_client_id             = module.azure_infra.identity_client_id
  identity_principal_id          = module.azure_infra.identity_principal_id
  aks_identity_principal_id      = module.azure_infra.aks_identity_principal_id
  identity_id                    = module.azure_infra.identity_id
  az_hosted_zone                 = var.az_hosted_zone
  public_app_gateway_id          = module.azure_infra.public_app_gateway_id
  public_app_gateway_ip          = module.azure_infra.public_app_gateway_ip
  internal_app_gateway_ip        = module.azure_infra.internal_app_gateway_ip
  agic_ssl_certificate_identifer = local.agic_ssl_certificate_identifer
  agic_internal                  = var.agic_internal
  enable_waf                     = var.enable_waf
  waf_mode                       = var.waf_mode
  waf_rule_set_version           = var.waf_rule_set_version
  waf_custom_rules               = var.waf_custom_rules

  depends_on = [module.azure_infra]

  providers = {
    helm = helm.aks
  }
}

module "azure_nected_app" {
  source = "./../modules/apps/common"

  count                        = var.app == true ? 1 : 0
  elasticsearch_provider       = "managed"
  elasticsearch_ip             = module.azure_infra.elasticsearch_ip
  elasticsearch_admin_username = var.elasticsearch_admin_username
  elasticsearch_admin_password = var.elasticsearch_admin_password
  backend_domain               = local.backend_domain
  router_domain                = local.router_domain
  ui_domain                    = local.ui_domain
  namespace                    = var.namespace
  nected_chart_version         = var.nected_chart_version

  pg_admin_user   = var.pg_admin_user
  pg_admin_passwd = var.pg_admin_passwd
  postgresql_host = module.azure_infra.postgresql_host

  temporal_pods_resources    = var.temporal_pods_resources
  temporal_pods_replicas     = var.temporal_pods_replicas
  temporal_task_partitions   = var.temporal_task_partitions
  temporal_history_shards    = var.temporal_history_shards
  temporal_persistant_driver = var.cassandra_node_count != 0 ? "cassandra" : "sql"

  nected_enable_garuda  = var.nected_enable_garuda
  nected_env_overrides  = var.nected_env_overrides
  nected_pods_replicas  = var.nected_pods_replicas
  nected_pods_resources = var.nected_pods_resources
  seed_node_list        = module.azure_infra.cassandra_seed_node_list

  use_managed_redis           = var.use_managed_cache
  redis_endpoint              = module.azure_infra.redis_endpoint
  redis_password              = module.azure_infra.redis_password
  redis_port                  = module.azure_infra.redis_port
  redis_tls_enabled           = module.azure_infra.redis_tls_enabled
  console_user_email          = var.console_user_email
  console_user_password       = var.console_user_password
  nected_pre_shared_key       = var.nected_pre_shared_key
  ingress_annotations         = local.ingress_annotations
  nected_existing_secret_name = var.nected_existing_secret_name
  nected_common_secret_value  = var.nected_common_secret_value
  nected_custom_ca            = var.nected_custom_ca

  helm_disable_openapi_validation = var.az_helm_disable_openapi_validation

  depends_on = [
    module.azure_agic,
    module.azure_infra
  ]
  providers = {
    helm = helm.aks
  }
}