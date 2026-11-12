############ AWS Infra Setup #############

module "aws_infra" {
  source = "./../modules/aws"

  project             = var.project
  environment         = var.environment
  agic_internal       = var.agic_internal
  aws_certificate_arn = var.aws_certificate_arn
  allowed_lb_cidrs    = var.allowed_lb_cidrs
  backend_domain      = local.backend_domain
  router_domain       = local.router_domain
  ui_domain           = local.ui_domain
  hosted_zone_domain  = var.base_domain
  route53_hosted_zone = var.route53_hosted_zone
  allowed_eks_cidrs   = var.allowed_k8s_cidrs

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

  # CloudWatch logging & alerting
  enable_cloudwatch_logging   = var.enable_cloudwatch_logging
  eks_log_retention_days      = var.eks_log_retention_days
  app_log_retention_days      = var.app_log_retention_days
  alert_emails                = var.alert_emails
  app_error_alarm_threshold   = var.app_error_alarm_threshold
  eks_control_plane_log_types = var.eks_control_plane_log_types

  # RDS database
  db_username              = var.pg_admin_user
  db_password              = local.pg_admin_passwd
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
  valkey_auth_token             = local.valkey_auth_token
  valkey_multi_az_enabled       = var.valkey_multi_az_enabled

  # Opensearch
  opensearch_engine_version           = var.opensearch_engine_version
  opensearch_instance_type            = var.opensearch_instance_type
  opensearch_instance_count           = var.opensearch_instance_count
  opensearch_admin_username           = var.opensearch_admin_username
  opensearch_admin_password           = local.opensearch_admin_password
  opensearch_volume_size              = var.opensearch_volume_size
  opensearch_volume_type              = var.opensearch_volume_type
  opensearch_tls_security_policy      = var.opensearch_tls_security_policy
  opensearch_dedicated_master_enabled = var.opensearch_dedicated_master_enabled
  opensearch_multi_az_enabled         = var.opensearch_multi_az_enabled

  # Cassandra
  aws_cassandra_vm_keypair    = var.aws_cassandra_vm_keypair
  cassandra_node_count        = var.cassandra_node_count
  cassandra_instance_type     = var.aws_cassandra_instance_type
  cassandra_data_disk_size_gb = var.cassandra_data_disk_size_gb

}


module "aws_alb" {
  count = var.app == true ? 1 : 0

  source           = "./../modules/apps/aws"
  eks_cluster_name = module.aws_infra.eks_cluster_name
  vpc_id           = module.aws_infra.vpc_id
  environment      = var.environment
  aws_region       = var.aws_region

  secret_manager = {
    enabled              = var.secret_manager.enabled
    namespace            = var.namespace
    service_account_name = var.secret_manager.service_account_name

    # Read-only, on both items the job may read. Secret ARNs carry a random
    # 6-character suffix, so the encryption-at-rest pattern ends in a wildcard.
    secret_arns = local.sm_enabled ? [
      aws_secretsmanager_secret.app[0].arn,
      aws_secretsmanager_secret.license[0].arn,
      "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${local.sm_ear_id}-*",
    ] : []

    kms_key_arn = var.secret_manager.kms_key_arn
  }

  depends_on = [
    module.aws_infra
  ]

  providers = {
    helm = helm.eks
  }
}

module "nected_app_aws" {
  source = "./../modules/apps/common"

  count                        = var.app == true ? 1 : 0
  elasticsearch_provider       = "opensearch"
  elasticsearch_ip             = module.aws_infra.opensearch_domain_endpoint
  elasticsearch_port           = 443
  elasticsearch_scheme         = "https"
  elasticsearch_admin_username = var.opensearch_admin_username
  elasticsearch_admin_password = local.opensearch_admin_password
  backend_domain               = local.backend_domain
  router_domain                = local.router_domain
  ui_domain                    = local.ui_domain
  namespace                    = var.namespace
  nected_chart_version         = var.nected_chart_version

  pg_admin_user   = var.pg_admin_user
  pg_admin_passwd = local.pg_admin_passwd
  postgresql_host = module.aws_infra.rds_endpoint

  temporal_pods_resources    = var.temporal_pods_resources
  temporal_pods_replicas     = var.temporal_pods_replicas
  temporal_task_partitions   = var.temporal_task_partitions
  temporal_history_shards    = var.temporal_history_shards
  temporal_persistant_driver = var.cassandra_node_count != 0 ? "cassandra" : "sql"
  seed_node_list             = module.aws_infra.seed_node_ips

  nected_enable_garuda  = var.nected_enable_garuda
  nected_env_overrides  = var.nected_env_overrides
  nected_pods_replicas  = var.nected_pods_replicas
  nected_pods_resources = var.nected_pods_resources

  use_managed_redis = var.use_managed_cache
  redis_endpoint    = module.aws_infra.cache_endpoint
  redis_password    = module.aws_infra.cache_auth_token
  redis_port        = module.aws_infra.cache_port
  redis_tls_enabled = module.aws_infra.cache_tls_enabled

  console_user_email          = var.console_user_email
  console_user_password       = local.console_user_passwd
  nected_pre_shared_key       = var.nected_pre_shared_key
  ingress_annotations         = local.ingress_annotations
  nected_existing_secret_name = var.nected_existing_secret_name
  nected_custom_ca            = var.nected_custom_ca

  secret_manager = {
    enabled       = var.secret_manager.enabled
    provider      = "aws"
    target_secret = var.secret_manager.target_secret

    # The item terraform created and populated.
    # app first, license second: later entries win.
    remote_keys   = local.sm_enabled ? [aws_secretsmanager_secret.app[0].name, aws_secretsmanager_secret.license[0].name] : []
    required_keys = var.secret_manager.required_keys
    aliases       = var.secret_manager.aliases
    fail_open     = var.secret_manager.fail_open
    aws_region    = var.aws_region

    # The chart owns the encryption-at-rest key and only ever READS this item.
    # Nothing populates it: terraform does not hold the key, and the job no
    # longer backs it up, so a generated key lives only in the Kubernetes
    # Secret until someone copies it out. See the chart's values.yaml.
    ear_secret_value = var.nected_common_secret_value == null ? "" : var.nected_common_secret_value
    ear_remote_key   = local.sm_enabled ? local.sm_ear_id : ""

    temporal_password_key = var.secret_manager.temporal_password_key
    service_account_name  = var.secret_manager.service_account_name

    # EKS Pod Identity binds the role to (namespace, service account)
    # server-side, so there is no annotation to set.
    service_account_role_arn = ""
  }

  ingress_enabled            = local.ingress_enabled
  targetgroupbinding_enabled = local.targetgroupbinding_enabled
  aws_tg_arns                = local.aws_tg_arns

  # The secret version, not just the secret: remote_keys only names the secret,
  # so without this the chart's hook can run before the value is written.
  depends_on = [
    module.aws_alb,
    module.aws_infra,
    aws_secretsmanager_secret_version.app,
    aws_secretsmanager_secret_version.license,
  ]

  providers = {
    helm = helm.eks
  }
}