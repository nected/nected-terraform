# main.tf
resource "azurerm_virtual_network" "prod" {
  name                = "${var.project}-vnet"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location
  address_space       = [var.vnet_address_space]

  tags = {
    environment = var.environment
    managed-by  = "terraform"
  }
}

resource "azurerm_subnet" "subnets" {
  for_each             = { for name, subnet in local.subnets : name => subnet }
  name                 = "${var.project}-snet-${each.key}"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.prod.name
  address_prefixes     = [each.value["address_prefixes"]]


  dynamic "delegation" {
    for_each = each.value["delegation"] ? [1] : []
    content {
      name = "delegation-postgresql"

      service_delegation {
        name = "Microsoft.DBforPostgreSQL/flexibleServers"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/join/action",
        ]
      }
    }
  }

  service_endpoints = each.value["service_endpoints"]

  depends_on = [azurerm_virtual_network.prod]
}

# Only create NSG for subnets that have security_rules defined
resource "azurerm_network_security_group" "nsg" {
  for_each = {
    for name, subnet in local.subnets : name => subnet
    if lookup(subnet, "security_rules", null) != null
  }

  name                = "${var.project}-nsg-${each.key}"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  # Create a security rule for each port with its specific source_address_prefix and direction
  dynamic "security_rule" {
    for_each = each.value["security_rules"]
    content {
      name                       = "${lower(security_rule.value.direction)}-${each.key}-port-${replace(security_rule.value.port, "-", "to")}"
      priority                   = 100 + security_rule.key
      direction                  = security_rule.value.direction
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = security_rule.value.port
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = "*"
    }
  }

  depends_on = [azurerm_virtual_network.prod]
}

# Associate NSGs with subnets (only for those with NSGs)
resource "azurerm_subnet_network_security_group_association" "associate" {
  for_each = {
    for name, subnet in local.subnets : name => subnet
    if lookup(subnet, "security_rules", null) != null
  }

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id

  depends_on = [
    azurerm_network_security_group.nsg,
    azurerm_virtual_network.prod
  ]
}