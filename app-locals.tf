locals {

  backend_domain            = "${var.backend_domain_prefix}.${var.base_domain}"
  router_domain             = "${var.router_domain_prefix}.${var.base_domain}"
  ui_domain                 = "${var.ui_domain_prefix}.${var.base_domain}"
  cert_secret_name          = "${var.project}-tls-${var.environment}"
  cert_vault_name           = "${var.project}-vault-${var.environment}"
  temporal_cluster_name     = "${var.project}-${var.environment}"
  alb_listener_cert_name    = "${var.project}-ssl-certificate"
  key_vault_id              = var.key_vault_name == "null" ? azurerm_key_vault.ssl_certs_vault[0].id : data.azurerm_key_vault.vault[0].id
  alb_vault_secret_endpoint = var.key_vault_name == "null" ? "https://${azurerm_key_vault.ssl_certs_vault[0].name}.vault.azure.net/secrets/${local.cert_secret_name}" : "https://${var.key_vault_name}.vault.azure.net/secrets/${var.key_vault_certificate_name}"
}