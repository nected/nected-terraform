locals {
  is_azure = var.cloud_provider == "azure"
  is_aws   = var.cloud_provider == "aws"

  k8s_host                   = local.is_azure ? data.azurerm_kubernetes_cluster.k8s[0].kube_config[0].host : ""
  k8s_client_certificate     = local.is_azure ? data.azurerm_kubernetes_cluster.k8s[0].kube_config[0].client_certificate : ""
  k8s_client_key             = local.is_azure ? data.azurerm_kubernetes_cluster.k8s[0].kube_config[0].client_key : ""
  k8s_cluster_ca_certificate = local.is_azure ? data.azurerm_kubernetes_cluster.k8s[0].kube_config[0].cluster_ca_certificate : ""

  eks_host       = local.is_aws ? data.aws_eks_cluster.this[0].endpoint : ""
  eks_ca_cert    = local.is_aws ? data.aws_eks_cluster.this[0].certificate_authority[0].data : ""
  eks_auth_token = local.is_aws ? data.aws_eks_cluster_auth.this[0].token : ""

  backend_domain = "${var.backend_domain_prefix}.${var.base_domain}"
  router_domain  = "${var.router_domain_prefix}.${var.base_domain}"
  ui_domain      = "${var.ui_domain_prefix}.${var.base_domain}"

  agic_ssl_certificate_identifer = "${var.project}-ssl-certificate"
  elasticsearch_ip               = local.is_azure ? module.azure_infra[0].elasticsearch_ip : module.aws_infra[0].opensearch_domain_endpoint
  elasticsearch_admin_username   = local.is_azure ? var.elasticsearch_admin_username : var.opensearch_admin_username
  elasticsearch_admin_password   = local.is_azure ? var.elasticsearch_admin_password : var.opensearch_admin_password
  seed_node_list                 = local.is_azure ? module.azure_infra[0].cassandra_seed_node_list : []
  postgresql_host                = local.is_azure ? module.azure_infra[0].postgresql_host : module.aws_infra[0].rds_endpoint

  redis_tls_enabled = local.is_azure ? module.azure_infra[0].redis_tls_enabled : module.aws_infra[0].cache_tls_enabled
  redis_endpoint    = local.is_azure ? module.azure_infra[0].redis_endpoint : module.aws_infra[0].cache_endpoint
  redis_port        = local.is_azure ? module.azure_infra[0].redis_port : module.aws_infra[0].cache_port
  redis_password    = local.is_azure ? module.azure_infra[0].redis_password : module.aws_infra[0].cache_auth_token

  az_ingress_annotations = local.is_azure ? {
    "kubernetes.io/ingress.class"                       = "azure/application-gateway"
    "appgw.ingress.kubernetes.io/ssl-redirect"          = "true"
    "appgw.ingress.kubernetes.io/use-private-ip"        = var.agic_internal ? "true" : "false"
    "appgw.ingress.kubernetes.io/appgw-ssl-certificate" = local.agic_ssl_certificate_identifer
  } : {}

  ingress_annotations        = local.is_azure ? local.az_ingress_annotations : {}
  ingress_enabled            = local.is_azure ? true : false
  targetgroupbinding_enabled = local.is_aws ? true : false
  aws_tg_arns                = local.is_aws ? module.aws_infra[0].target_group_arns : {}
}