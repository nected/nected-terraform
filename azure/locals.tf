locals {
  k8s_host                   = data.azurerm_kubernetes_cluster.k8s.kube_config[0].host
  k8s_client_certificate     = data.azurerm_kubernetes_cluster.k8s.kube_config[0].client_certificate
  k8s_client_key             = data.azurerm_kubernetes_cluster.k8s.kube_config[0].client_key
  k8s_cluster_ca_certificate = data.azurerm_kubernetes_cluster.k8s.kube_config[0].cluster_ca_certificate


  backend_domain = "${var.backend_domain_prefix}.${var.base_domain}"
  router_domain  = "${var.router_domain_prefix}.${var.base_domain}"
  ui_domain      = "${var.ui_domain_prefix}.${var.base_domain}"

  agic_ssl_certificate_identifer = "${var.project}-ssl-certificate"

  az_ingress_annotations = {
    "kubernetes.io/ingress.class"                       = "azure/application-gateway"
    "appgw.ingress.kubernetes.io/ssl-redirect"          = "true"
    "appgw.ingress.kubernetes.io/use-private-ip"        = var.agic_internal ? "true" : "false"
    "appgw.ingress.kubernetes.io/appgw-ssl-certificate" = local.agic_ssl_certificate_identifer
  }

  ingress_annotations        = local.az_ingress_annotations
  ingress_enabled            = true 
}