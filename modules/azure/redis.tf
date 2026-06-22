# Azure Managed Redis (replaces the retired Azure Cache for Redis).
# AMR has no subnet injection, so private access is provided via a
# private endpoint + private DNS zone (same pattern as PostgreSQL).
resource "azurerm_managed_redis" "redis" {
  count = var.use_managed_redis ? 1 : 0

  name                = "${var.project}-redis"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  sku_name            = var.redis_sku_name

  high_availability_enabled = true

  # Reachable only over the private endpoint below.
  public_network_access = "Disabled"

  default_database {
    # Encrypted = TLS. EnterpriseCluster presents a single endpoint so
    # non-cluster-aware clients keep working like the old Premium instance.
    client_protocol                    = "Encrypted"
    clustering_policy                   = "EnterpriseCluster"
    access_keys_authentication_enabled = true
  }

  tags = {
    environment = var.environment
    managed-by  = "terraform"
  }
}

# Private DNS zone for Azure Managed Redis.
# AMR endpoints live under redis.azure.net, so the privatelink zone must be
# privatelink.redis.azure.net (NOT the older redisenterprise.cache.azure.net).
resource "azurerm_private_dns_zone" "redis" {
  count = var.use_managed_redis ? 1 : 0

  name                = "privatelink.redis.azure.net"
  resource_group_name = local.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  count = var.use_managed_redis ? 1 : 0

  name                  = "${var.project}-redis-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.redis[0].name
  virtual_network_id    = local.vnet_id
  resource_group_name   = local.resource_group_name

  depends_on = [
    azurerm_virtual_network.prod,
    azurerm_subnet.subnets
  ]
}

resource "azurerm_private_endpoint" "redis" {
  count = var.use_managed_redis ? 1 : 0

  name                = "${var.project}-redis-pe"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  subnet_id           = var.existing_vnet_name == "" ? azurerm_subnet.subnets["redis"].id : data.azurerm_subnet.existing["redis"].id

  private_service_connection {
    name                           = "${var.project}-redis-psc"
    private_connection_resource_id = azurerm_managed_redis.redis[0].id
    is_manual_connection           = false
    subresource_names              = ["redisEnterprise"]
  }

  private_dns_zone_group {
    name                 = "redis-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.redis[0].id]
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.redis
  ]
}

resource "time_sleep" "wait_for_redis" {
  count = var.use_managed_redis ? 1 : 0
  depends_on = [
    azurerm_managed_redis.redis,
    azurerm_private_endpoint.redis
  ]

  create_duration = "5m"
}
