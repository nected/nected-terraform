# Public IP for Application Gateway
resource "azurerm_public_ip" "appgw_pip" {
  name                = "${var.project}-appgw-pip-${var.environment}"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    createdby   = "terraform"
  }
}

resource "azurerm_dns_a_record" "router" {
  count = var.az_hosted_zone == false ? 0 : 1

  name                = var.router_domain
  zone_name           = data.azurerm_dns_zone.dns_zone[0].name
  resource_group_name = var.hosted_zone_rg == "null" ? local.resource_group_name : var.hosted_zone_rg
  ttl                 = 300
  records             = [local.dns_record_ip]

  depends_on = [
    azurerm_public_ip.appgw_pip
  ]
}

resource "azurerm_dns_a_record" "ui" {
  count = var.az_hosted_zone == false ? 0 : 1

  name                = var.ui_domain
  zone_name           = data.azurerm_dns_zone.dns_zone[0].name
  resource_group_name = var.hosted_zone_rg == "null" ? local.resource_group_name : var.hosted_zone_rg
  ttl                 = 300
  records             = [local.dns_record_ip]

  depends_on = [
    azurerm_public_ip.appgw_pip
  ]
}

resource "azurerm_dns_a_record" "backend" {
  count = var.az_hosted_zone == false ? 0 : 1

  name                = var.backend_domain
  zone_name           = data.azurerm_dns_zone.dns_zone[0].name
  resource_group_name = var.hosted_zone_rg == "null" ? local.resource_group_name : var.hosted_zone_rg
  ttl                 = 300
  records             = [local.dns_record_ip]

  depends_on = [
    azurerm_public_ip.appgw_pip
  ]
}