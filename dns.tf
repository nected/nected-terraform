resource "azurerm_dns_a_record" "router" {
  name                = var.router_domain_prefix
  zone_name           = data.azurerm_dns_zone.dns_zone.name
  resource_group_name = var.hosted_zone_rg == "null" ? local.resource_group_name : var.hosted_zone_rg
  ttl                 = 300
  records             = [azurerm_public_ip.appgw_pip.ip_address]

  depends_on = [
    azurerm_public_ip.appgw_pip
  ]
}

resource "azurerm_dns_a_record" "ui" {
  name                = var.ui_domain_prefix
  zone_name           = data.azurerm_dns_zone.dns_zone.name
  resource_group_name = var.hosted_zone_rg == "null" ? local.resource_group_name : var.hosted_zone_rg
  ttl                 = 300
  records             = [azurerm_public_ip.appgw_pip.ip_address]

  depends_on = [
    azurerm_public_ip.appgw_pip
  ]
}

resource "azurerm_dns_a_record" "backend" {
  name                = var.backend_domain_prefix
  zone_name           = data.azurerm_dns_zone.dns_zone.name
  resource_group_name = var.hosted_zone_rg == "null" ? local.resource_group_name : var.hosted_zone_rg
  ttl                 = 300
  records             = [azurerm_public_ip.appgw_pip.ip_address]

  depends_on = [
    azurerm_public_ip.appgw_pip
  ]
}