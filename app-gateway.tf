# Azure Application Gateway with SSL and AKS Integration

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

# Internal Application Gateway
resource "azurerm_application_gateway" "appgw" {
  name                = "${var.project}-appgw-${var.environment}"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location

  sku {
    name     = var.appgw_sku_name
    tier     = var.appgw_sku_tier
    capacity = var.enable_autoscaling ? null : var.appgw_capacity
  }

  # Autoscaling configuration (for v2 SKUs)
  dynamic "autoscale_configuration" {
    for_each = var.enable_autoscaling ? [1] : []
    content {
      min_capacity = var.appgw_min_capacity
      max_capacity = var.appgw_max_capacity
    }
  }

  gateway_ip_configuration {
    name      = "${var.project}-gateway-ip-configuration"
    subnet_id = azurerm_subnet.subnets["appgw"].id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.public_frontend_name
    public_ip_address_id = local.public_app_gateway_id
  }
  # Frontend IP configuration
  frontend_ip_configuration {
    name                          = local.private_frontend_name
    subnet_id                     = azurerm_subnet.subnets["appgw"].id
    private_ip_address            = local.internal_app_gateway_ip
    private_ip_address_allocation = "Static"
  }

  # Backend address pool for AKS services
  backend_address_pool {
    name = "${var.project}-aks-backend-pool"
  }

  # Backend HTTP settings
  backend_http_settings {
    name                                = "${var.project}-backend-http-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 60
    probe_name                          = "${var.project}-health-probe"
    pick_host_name_from_backend_address = true
  }

  probe {
    name                                      = "${var.project}-health-probe"
    protocol                                  = "Http"
    path                                      = var.health_probe_path
    host                                      = var.health_probe_host != "" ? var.health_probe_host : null
    pick_host_name_from_backend_http_settings = var.health_probe_host == "" ? true : false
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3

    match {
      status_code = ["200-399"]
    }
  }

  http_listener {
    name                           = "${var.project}-http-listener"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                        = "${var.project}-http-routing-rule"
    rule_type                   = "Basic"
    http_listener_name          = "${var.project}-http-listener"
    redirect_configuration_name = var.ssl_certificate_path != "" || var.ssl_certificate_data != "" ? "${var.project}-http-to-https-redirect" : null
    backend_address_pool_name   = var.ssl_certificate_path == "" && var.ssl_certificate_data == "" ? "${var.project}-aks-backend-pool" : null
    backend_http_settings_name  = var.ssl_certificate_path == "" && var.ssl_certificate_data == "" ? "${var.project}-backend-http-settings" : null
    priority                    = 100
  }

  # Identity for Key Vault access
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity.id]
  }

  tags = {
    Environment = var.environment
    createdby   = "terraform"
  }

  # Lifecycle to prevent recreation on minor changes
  lifecycle {
    ignore_changes = [
      tags,
      backend_address_pool,
      backend_http_settings,
      probe,
      http_listener,
      request_routing_rule,
      frontend_port,
      ssl_certificate
    ]
  }
}

# Role assignment for AGIC managed identity to manage Application Gateway
resource "azurerm_role_assignment" "appgw_identity_contributor" {
  scope                = azurerm_application_gateway.appgw.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

# Role assignment for AGIC managed identity to read AKS cluster
resource "azurerm_role_assignment" "appgw_identity_aks_reader" {
  scope                = azurerm_kubernetes_cluster.k8s.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

# Role assignment for AGIC managed identity to operate on itself (assign to resources)
resource "azurerm_role_assignment" "appgw_identity_operator" {
  scope                = azurerm_user_assigned_identity.identity.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

# Role assignment for AGIC to read AKS node resource group (for route tables in Kubenet)
resource "azurerm_role_assignment" "appgw_identity_node_rg_reader" {
  scope                = azurerm_kubernetes_cluster.k8s.node_resource_group_id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

# Role assignment for AKS to access App Gateway
resource "azurerm_role_assignment" "aks_appgw_contributor" {
  scope                = azurerm_application_gateway.appgw.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.k8s.identity[0].principal_id
}