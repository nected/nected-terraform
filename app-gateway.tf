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

# WAF Policy with custom rules
resource "azurerm_web_application_firewall_policy" "waf_policy" {
  count               = var.enable_waf ? 1 : 0
  name                = "${var.project}-waf-policy-${var.environment}"
  resource_group_name = local.resource_group_name
  location            = local.resource_group_location

  policy_settings {
    enabled = true
    mode    = var.waf_mode
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = var.waf_rule_set_version
    }

  }

  # Always allow GraphQL endpoint through WAF
  custom_rules {
    name      = "AllowGraphQL"
    priority  = 1
    rule_type = "MatchRule"
    action    = "Allow"

    match_conditions {
      match_variables {
        variable_name = "RequestUri"
      }
      operator     = "Contains"
      match_values = ["/graphql/query"]
    }
  }

  dynamic "custom_rules" {
    for_each = local.waf_custom_rules_with_offset
    content {
      name      = custom_rules.value.name
      priority  = custom_rules.value.priority
      rule_type = custom_rules.value.rule_type
      action    = custom_rules.value.action

      dynamic "match_conditions" {
        for_each = custom_rules.value.match_conditions
        content {
          dynamic "match_variables" {
            for_each = match_conditions.value.match_variables
            content {
              variable_name = match_variables.value.variable_name
              selector      = match_variables.value.selector
            }
          }
          operator           = match_conditions.value.operator
          negation_condition = match_conditions.value.negation_condition
          match_values       = match_conditions.value.match_values
        }
      }
    }
  }

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
    name     = var.enable_waf ? "WAF_v2" : var.appgw_sku_name
    tier     = var.enable_waf ? "WAF_v2" : var.appgw_sku_tier
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

  firewall_policy_id = var.enable_waf ? azurerm_web_application_firewall_policy.waf_policy[0].id : null

  gateway_ip_configuration {
    name      = "${var.project}-gateway-ip-configuration"
    subnet_id = var.existing_vnet_name == "" ? azurerm_subnet.subnets["appgw"].id : data.azurerm_subnet.existing["appgw"].id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = local.public_frontend_name
    public_ip_address_id = local.public_app_gateway_id
  }
  # Frontend IP configuration
  frontend_ip_configuration {
    name                          = local.private_frontend_name
    subnet_id                     = var.existing_vnet_name == "" ? azurerm_subnet.subnets["appgw"].id : data.azurerm_subnet.existing["appgw"].id
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

  http_listener {
    name                           = "${var.project}-https-listener"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "https-port"
    protocol                       = "Https"
    ssl_certificate_name           = "${var.project}-ssl-certificate"
  }

  request_routing_rule {
    name                       = "${var.project}-https-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "${var.project}-https-listener"
    backend_address_pool_name  = "${var.project}-aks-backend-pool"
    backend_http_settings_name = "${var.project}-backend-http-settings"
    priority                   = 100
  }

  ssl_certificate {
    name = local.alb_listener_cert_name
    # Using versionless URI for automatic certificate rotation
    key_vault_secret_id = local.alb_vault_secret_endpoint
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
      frontend_port,
      request_routing_rule,
      redirect_configuration
    ]
  }

  depends_on = [
    time_sleep.wait_for_keyvaultsync,
    helm_release.azurecert
  ]
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