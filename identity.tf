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
  scope                = data.azurerm_dns_zone.dns_zone.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}


resource "azurerm_federated_identity_credential" "cert_manager" {
  name                = "${var.project}-cert-manager-federated-identity-${var.environment}"
  resource_group_name = local.resource_group_name
  parent_id           = azurerm_user_assigned_identity.identity.id
  issuer              = azurerm_kubernetes_cluster.k8s.oidc_issuer_url
  audience            = ["api://AzureADTokenExchange"]
  subject             = "system:serviceaccount:cert-manager:cert-manager"
}