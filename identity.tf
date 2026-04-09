# User Assigned Managed Identity for Application Gateway
resource "azurerm_user_assigned_identity" "identity" {
  name                = "${var.project}-identity-${var.environment}"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location

  tags = {
    Environment = var.environment
    createdby   = "terraform"
  }
}

# Role assignment for AGIC managed identity to read resource group
resource "azurerm_role_assignment" "appgw_identity_reader" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

# Role assignment for App Gateway to access AKS
resource "azurerm_role_assignment" "appgw_aks_network_contributor" {
  scope                = azurerm_virtual_network.prod.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

# Create role assignment for DNS Zone Contributor
resource "azurerm_role_assignment" "dns_contributor" {
  count                = var.az_hosted_zone == false ? 0 : 1
  scope                = data.azurerm_dns_zone.dns_zone[0].id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

# federated identity for cert-manager
resource "azurerm_federated_identity_credential" "cert_manager" {
  count = var.key_vault_name == "null" ? 1 : 0

  name                      = "${var.project}-cert-manager-federated-identity-${var.environment}"
  user_assigned_identity_id = azurerm_user_assigned_identity.identity.id
  issuer                    = azurerm_kubernetes_cluster.k8s.oidc_issuer_url
  audience                  = ["api://AzureADTokenExchange"]
  subject                   = "system:serviceaccount:cert-manager:cert-manager"
}

# Federated Identity for keyvault sync
resource "azurerm_federated_identity_credential" "keyvault_sync" {
  count = var.key_vault_name == "null" ? 1 : 0

  name                      = "${var.project}-keyvault-certificate-${var.environment}"
  user_assigned_identity_id = azurerm_user_assigned_identity.identity.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azurerm_kubernetes_cluster.k8s.oidc_issuer_url
  subject                   = "system:serviceaccount:${var.namespace}:keyvault-sync-sa"
}

#
resource "azurerm_key_vault" "ssl_certs_vault" {
  count = var.key_vault_name == "null" ? 1 : 0

  name                        = local.cert_vault_name
  location                    = local.resource_group_location
  resource_group_name         = local.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 90
  purge_protection_enabled    = false

  sku_name = "standard"

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"

    virtual_network_subnet_ids = [
      azurerm_subnet.subnets["appgw"].id
    ]
  }

  rbac_authorization_enabled = true
}

resource "azurerm_role_assignment" "kv_certificate" {
  scope                = local.key_vault_id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

resource "azurerm_role_assignment" "appgw_kv_secrets" {
  scope                = local.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}