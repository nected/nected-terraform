# Create private DNS zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgresql" {
  name                = "${var.project}.postgres.database.azure.com"
  resource_group_name = local.resource_group_name
}

# Link private DNS zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "${var.project}-psql-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = azurerm_virtual_network.prod.id
  resource_group_name   = local.resource_group_name

  depends_on = [
    azurerm_virtual_network.prod,
    azurerm_subnet.subnets
  ]
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "postgresql" {
  name                   = "${var.project}-psql"
  location               = local.resource_group_location
  resource_group_name    = local.resource_group_name
  version                = var.pg_version
  administrator_login    = var.pg_admin_user
  administrator_password = var.pg_admin_passwd
  storage_mb             = 32768
  sku_name               = var.pg_sku_name
  //zone                   = "1"

  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  public_network_access_enabled = false
  delegated_subnet_id           = azurerm_subnet.subnets["psql"].id
  private_dns_zone_id           = azurerm_private_dns_zone.postgresql.id

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgresql,
    azurerm_virtual_network.prod
  ]

}

resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.postgresql.id
  value     = "BTREE_GIN,VECTOR"
}

resource "azurerm_postgresql_flexible_server_database" "postgresql_db" {
  name      = "nected"
  server_id = azurerm_postgresql_flexible_server.postgresql.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}