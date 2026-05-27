# Redis Cache with Standard SKU
resource "azurerm_redis_cache" "redis" {
  count = var.use_managed_redis ? 1 : 0

  name                = "${var.project}-redis"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  capacity            = var.redis_capacity
  family              = "P"
  sku_name            = "Premium"
  minimum_tls_version = "1.2"

  # For private endpoint access, disable public access
  public_network_access_enabled = false

  subnet_id = var.existing_vnet_name == "" ? azurerm_subnet.subnets["redis"].id : data.azurerm_subnet.existing["redis"].id

  redis_configuration {
    # Standard SKU configurations
  }

  tags = {
    environment = var.environment
    managed-by  = "terraform"
  }
}

resource "time_sleep" "wait_for_redis" {
  count = var.use_managed_redis ? 1 : 0
  depends_on = [
    azurerm_redis_cache.redis,
    //azurerm_private_endpoint.redis
  ]

  create_duration = "5m"
}