locals {

  backend_domain   = "${var.backend_domain_prefix}.${var.hosted_zone}"
  router_domain    = "${var.router_domain_prefix}.${var.hosted_zone}"
  ui_domain        = "${var.ui_domain_prefix}.${var.hosted_zone}"
  cert_secret_name = "${var.project}-tls-${var.environment}"

  temporal_cluster_name = "${var.project}-${var.environment}"
}