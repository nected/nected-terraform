# network.tf

resource "azurerm_virtual_network" "prod" {
  count = var.existing_vnet_name == "" ? 1 : 0

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
  for_each = { for name, subnet in local.subnets : name => subnet if var.existing_vnet_name == "" }

  name                 = "${var.project}-snet-${each.key}"
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.vnet_name
  address_prefixes     = [each.value["address_prefixes"]]

  # Private settings applied only where needed — no need for a separate public map
  private_endpoint_network_policies             = contains(keys(local.subnets_to_private), each.key) ? "Disabled" : "Enabled"
  private_link_service_network_policies_enabled = contains(keys(local.subnets_to_private), each.key) ? false : true
  default_outbound_access_enabled               = contains(keys(local.subnets_to_private), each.key) ? false : true

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

# Only create NAT Gateway when there are private subnets
resource "azurerm_nat_gateway" "this" {
  count               = local.create_nat_gateway ? 1 : 0
  name                = "${var.project}-natgw"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  tags = {
    environment = var.environment
    managed-by  = "terraform"
  }
}

# Associate NAT Gateway only to private subnets being created
resource "azurerm_subnet_nat_gateway_association" "this" {
  for_each = local.subnets_to_private

  subnet_id      = azurerm_subnet.subnets[each.key].id
  nat_gateway_id = azurerm_nat_gateway.this[0].id
}

# Only create NSG for subnets that have security_rules defined
resource "azurerm_network_security_group" "nsg" {
  # for_each = {
  #   for name, subnet in local.subnets : name => subnet
  #   if lookup(subnet, "security_rules", null) != null
  # }

  for_each = local.nsg_to_create

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
      destination_port_ranges    = [security_rule.value.port]
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = "*"
    }
  }

  depends_on = [azurerm_virtual_network.prod]
}

# Associate NSGs with subnets (only for those with NSGs)
resource "azurerm_subnet_network_security_group_association" "associate" {
  # for_each = {
  #   for name, subnet in local.subnets : name => subnet
  #   if lookup(subnet, "security_rules", null) != null
  # }

  for_each = local.nsg_to_create

  subnet_id                 = contains(keys(var.existing_subnets), each.key) ? data.azurerm_subnet.existing[each.key].id : azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id

  depends_on = [
    azurerm_network_security_group.nsg,
    azurerm_virtual_network.prod
  ]
}