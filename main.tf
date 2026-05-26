############ Azure Infra Setup #############
module "azure_infra" {
  source = "./modules/azure"

  count = local.is_azure ? 1 : 0

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

  # Postgresql
  pg_version          = var.pg_version
  pg_admin_user       = var.pg_admin_user
  pg_admin_passwd     = var.pg_admin_passwd
  pg_sku_name         = var.az_pg_sku_name
  pg_disk_size        = var.az_pg_disk_size
  pg_backup_retention = var.pg_backup_retention

  # Cache
  use_managed_redis = var.use_managed_cache
  redis_capacity    = var.az_redis_capacity

  # ElasticSearch
  elasticsearch_version         = var.elasticsearch_version
  elasticsearch_vm_size         = var.elasticsearch_vm_size
  elasticsearch_admin_username  = var.elasticsearch_admin_username
  elasticsearch_admin_password  = var.elasticsearch_admin_password
  elasticsearch_os_disk_size_gb = var.elasticsearch_os_disk_size_gb

  # Cassandra
  cassandra_node_count        = var.cassandra_node_count
  cassandra_vm_size           = var.cassandra_vm_size
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
  source = "./modules/apps/azure"

  count = local.is_azure && var.app == true ? 1 : 0

  alb_vault_secret_endpoint      = module.azure_infra[0].alb_vault_secret_endpoint
  backend_domain                 = local.backend_domain
  router_domain                  = local.router_domain
  ui_domain                      = local.ui_domain
  resource_group_location        = module.azure_infra[0].resource_group_location
  resource_group_name            = var.az_resource_group_name
  environment                    = var.environment
  base_domain                    = var.base_domain
  namespace                      = var.namespace
  project                        = var.project
  key_vault_name                 = var.az_key_vault_name
  appgw_subnet_id                = module.azure_infra[0].subnets["appgw"].id
  cert_secret_name               = module.azure_infra[0].cert_secret_name
  cert_vault_name                = module.azure_infra[0].cert_vault_name
  hosted_zone_rg                 = var.az_hosted_zone_rg
  console_user_email             = var.console_user_email
  subscription_id                = var.az_subscription_id
  identity_client_id             = module.azure_infra[0].identity_client_id
  identity_principal_id          = module.azure_infra[0].identity_principal_id
  aks_identity_principal_id      = module.azure_infra[0].aks_identity_principal_id
  identity_id                    = module.azure_infra[0].identity_id
  az_hosted_zone                 = var.az_hosted_zone
  public_app_gateway_id          = module.azure_infra[0].public_app_gateway_id
  public_app_gateway_ip          = module.azure_infra[0].public_app_gateway_ip
  internal_app_gateway_ip        = module.azure_infra[0].internal_app_gateway_ip
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
  source = "./modules/apps/common"

  count                        = local.is_azure && var.app == true ? 1 : 0
  elasticsearch_provider       = "managed"
  elasticsearch_ip             = local.elasticsearch_ip
  elasticsearch_admin_username = local.elasticsearch_admin_username
  elasticsearch_admin_password = local.elasticsearch_admin_password
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

  use_managed_redis           = var.use_managed_cache
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

  helm_disable_openapi_validation = var.az_helm_disable_openapi_validation

  depends_on = [
    module.azure_agic,
    module.azure_infra
  ]
  providers = {
    helm = helm.aks
  }
}


module "aws_infra" {
  source = "./modules/aws"

  count = local.is_aws ? 1 : 0

  project             = var.project
  environment         = var.environment
  agic_internal       = var.agic_internal
  aws_certificate_arn = var.aws_certificate_arn
  backend_domain      = local.backend_domain
  router_domain       = local.router_domain
  ui_domain           = local.ui_domain

  # Network
  vpc_cidr                  = var.vpc_cidr
  azs                       = var.azs
  subnet_newbits            = var.subnet_newbits
  single_nat_gateway        = var.single_nat_gateway
  existing_vpc_id           = var.existing_vpc_id
  existing_private_subnets  = var.existing_private_subnets
  existing_database_subnets = var.existing_database_subnets
  existing_public_subnets   = var.existing_public_subnets

  # EKS
  node_instance_types    = var.eks_node_instance_types
  node_desired_count     = var.k8s_node_count
  node_min_count         = var.k8s_min_node_count
  node_max_count         = var.k8s_max_node_count
  endpoint_public_access = var.eks_endpoint_public_access

  # RDS database
  db_username              = var.pg_admin_user
  db_password              = var.pg_admin_passwd
  db_engine_version        = var.pg_version
  backup_retention_period  = var.pg_backup_retention
  db_instance_class        = var.db_instance_class
  db_allocated_storage     = var.db_allocated_storage
  db_max_allocated_storage = var.db_max_allocated_storage
  db_storage_type          = var.db_storage_type
  db_multi_az              = var.db_multi_az
  db_publicly_accessible   = var.db_publicly_accessible
  db_deletion_protection   = var.db_deletion_protection
  maintenance_window       = var.maintenance_window
  backup_window            = var.backup_window
  skip_final_snapshot      = var.skip_final_snapshot
  delete_automated_backups = var.delete_automated_backups

  # Valkey Cache
  use_managed_redis             = var.use_managed_cache
  valkey_port                   = var.valkey_port
  valkey_engine                 = var.valkey_engine
  valkey_engine_version         = var.valkey_engine_version
  valkey_node_type              = var.valkey_node_type
  valkey_num_cache_nodes        = var.valkey_num_cache_nodes
  valkey_parameter_group_family = var.valkey_parameter_group_family
  valkey_auth_token             = var.valkey_auth_token
  valkey_multi_az_enabled       = var.valkey_multi_az_enabled

  # Opensearch
  opensearch_engine_version           = var.opensearch_engine_version
  opensearch_instance_type            = var.opensearch_instance_type
  opensearch_instance_count           = var.opensearch_instance_count
  opensearch_admin_username           = var.opensearch_admin_username
  opensearch_admin_password           = var.opensearch_admin_password
  opensearch_volume_size              = var.opensearch_volume_size
  opensearch_volume_type              = var.opensearch_volume_type
  opensearch_tls_security_policy      = var.opensearch_tls_security_policy
  opensearch_dedicated_master_enabled = var.opensearch_dedicated_master_enabled
  opensearch_multi_az_enabled         = var.opensearch_multi_az_enabled
}


module "aws_alb" {
  count = local.is_aws && var.app == true ? 1 : 0

  source                = "./modules/apps/aws"
  eks_cluster_name      = module.aws_infra[0].eks_cluster_name
  vpc_id                = module.aws_infra[0].vpc_id
  environment           = var.environment
  eks_oidc_provider_arn = module.aws_infra[0].eks_oidc_provider_arn
  eks_oidc_provider_url = module.aws_infra[0].eks_cluster_oidc_issuer_url

  depends_on = [
    module.aws_infra
  ]

  providers = {
    helm = helm.eks
  }
}

module "nected_app_aws" {
  source = "./modules/apps/common"

  count                        = local.is_aws && var.app == true ? 1 : 0
  elasticsearch_provider       = "opensearch"
  elasticsearch_ip             = local.elasticsearch_ip
  elasticsearch_port           = 443
  elasticsearch_scheme         = "https"
  elasticsearch_admin_username = local.elasticsearch_admin_username
  elasticsearch_admin_password = local.elasticsearch_admin_password
  backend_domain               = local.backend_domain
  router_domain                = local.router_domain
  ui_domain                    = local.ui_domain
  namespace                    = var.namespace

  pg_admin_user   = var.pg_admin_user
  pg_admin_passwd = var.pg_admin_passwd
  postgresql_host = local.postgresql_host

  temporal_pods_resources  = var.temporal_pods_resources
  temporal_pods_replicas   = var.temporal_pods_replicas
  temporal_task_partitions = var.temporal_task_partitions
  temporal_history_shards  = var.temporal_history_shards
  # temporal_persistant_driver = var.cassandra_node_count != 0 ? "cassandra" : "sql"

  nected_enable_garuda  = var.nected_enable_garuda
  nected_env_overrides  = var.nected_env_overrides
  nected_pods_replicas  = var.nected_pods_replicas
  nected_pods_resources = var.nected_pods_resources
  # seed_node_list        = local.seed_node_list

  use_managed_redis           = var.use_managed_cache
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

  ingress_enabled            = local.ingress_enabled
  targetgroupbinding_enabled = local.targetgroupbinding_enabled
  aws_tg_arns                = local.aws_tg_arns

  depends_on = [
    module.aws_alb,
    module.aws_infra
  ]

  providers = {
    helm = helm.eks
  }
}