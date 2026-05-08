locals {
  is_azure = var.cloud_provider == "azure"
  is_aws   = var.cloud_provider == "aws"
  
  backend_domain          = "${var.backend_domain_prefix}.${var.base_domain}"
  router_domain           = "${var.router_domain_prefix}.${var.base_domain}"
  ui_domain               = "${var.ui_domain_prefix}.${var.base_domain}"
}