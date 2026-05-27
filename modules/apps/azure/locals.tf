locals {
  dns_record_ip                  = var.agic_internal ? var.internal_app_gateway_ip : var.public_app_gateway_ip
  frontend_ip_configuration_name = "${var.project}-frontend-ip"
  ingress_use_private            = var.agic_internal ? "true" : "false"

  private_frontend_name = var.agic_internal ? local.frontend_ip_configuration_name : "${var.project}-frontend-ip-not-use"
  public_frontend_name  = var.agic_internal ? "${var.project}-frontend-ip-not-use" : local.frontend_ip_configuration_name

  waf_custom_rules_with_offset = [
    for rule in var.waf_custom_rules : merge(rule, {
      priority = rule.priority + 10
    })
  ]

  hosted_zone_rg = var.hosted_zone_rg == "null" ? var.resource_group_name : var.hosted_zone_rg
}