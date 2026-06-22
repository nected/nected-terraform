locals {
  eks_host       = data.aws_eks_cluster.this.endpoint
  eks_ca_cert    = data.aws_eks_cluster.this.certificate_authority[0].data
  eks_auth_token = data.aws_eks_cluster_auth.this.token

  backend_domain = "${var.backend_domain_prefix}.${var.base_domain}"
  router_domain  = "${var.router_domain_prefix}.${var.base_domain}"
  ui_domain      = "${var.ui_domain_prefix}.${var.base_domain}"

  ingress_annotations        = {}
  ingress_enabled            = false
  targetgroupbinding_enabled = true
  aws_tg_arns                = module.aws_infra.target_group_arns
}