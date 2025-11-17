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

# Application Gateway
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

  # Frontend port for HTTP
  frontend_port {
    name = "http-port"
    port = 80
  }

  # Frontend port for HTTPS
  # frontend_port {
  #   name = "https-port"
  #   port = 443
  # }

  # Frontend IP configuration
  frontend_ip_configuration {
    name                 = "${var.project}-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  # Backend address pool for AKS services
  backend_address_pool {
    name = "${var.project}-aks-backend-pool"
    # Backend addresses will be populated by AKS services
    # fqdns = var.aks_service_fqdns # Optional: if using FQDN
  }

  # Additional backend pools can be added dynamically
  # dynamic "backend_address_pool" {
  #   for_each = var.additional_backend_pools
  #   content {
  #     name  = backend_address_pool.value.name
  #     fqdns = lookup(backend_address_pool.value, "fqdns", null)
  #     ip_addresses = lookup(backend_address_pool.value, "ip_addresses", null)
  #   }
  # }

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

  # # Backend HTTPS settings
  # backend_http_settings {
  #   name                                = "${var.project}-backend-https-settings"
  #   cookie_based_affinity               = "Disabled"
  #   port                                = 443
  #   protocol                            = "Https"
  #   request_timeout                     = 60
  #   probe_name                          = "${var.project}-https-health-probe"
  #   pick_host_name_from_backend_address = true

  #   connection_draining {
  #     enabled           = true
  #     drain_timeout_sec = 30
  #   }
  # }

  # Health probe for HTTP
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

  # Health probe for HTTPS
  # probe {
  #   name                                      = "${var.project}-https-health-probe"
  #   protocol                                  = "Https"
  #   path                                      = var.health_probe_path
  #   host                                      = var.health_probe_host != "" ? var.health_probe_host : null
  #   pick_host_name_from_backend_http_settings = var.health_probe_host == "" ? true : false
  #   interval                                  = 30
  #   timeout                                   = 30
  #   unhealthy_threshold                       = 3

  #   match {
  #     status_code = ["200-399"]
  #   }
  # }

  # SSL Certificate - Option 1: File-based (for development)
  # dynamic "ssl_certificate" {
  #   for_each = var.ssl_certificate_path != "" ? [1] : []
  #   content {
  #     name     = "${var.project}-ssl-cert"
  #     data     = filebase64(var.ssl_certificate_path)
  #     password = var.ssl_certificate_password
  #   }
  # }

  # SSL Certificate - Option 2: Data-based (for production with Key Vault)
  # dynamic "ssl_certificate" {
  #   for_each = var.ssl_certificate_data != "" ? [1] : []
  #   content {
  #     name     = "${var.project}-ssl-cert-data"
  #     data     = var.ssl_certificate_data
  #     password = var.ssl_certificate_password
  #   }
  # }

  # # Trusted root certificate for backend SSL
  # dynamic "trusted_root_certificate" {
  #   for_each = var.backend_ssl_cert_path != "" ? [1] : []
  #   content {
  #     name = "${var.project}-backend-root-cert"
  #     data = filebase64(var.backend_ssl_cert_path)
  #   }
  # }

  # HTTP Listener
  http_listener {
    name                           = "${var.project}-http-listener"
    frontend_ip_configuration_name = "${var.project}-frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  # HTTPS Listener (only if SSL certificate is configured)
  # dynamic "http_listener" {
  #   for_each = var.ssl_certificate_path != "" || var.ssl_certificate_data != "" ? [1] : []
  #   content {
  #     name                           = "${var.project}-https-listener"
  #     frontend_ip_configuration_name = "${var.project}-frontend-ip"
  #     frontend_port_name             = "https-port"
  #     protocol                       = "Https"
  #     ssl_certificate_name           = var.ssl_certificate_path != "" ? "${var.project}-ssl-cert" : "${var.project}-ssl-cert-data"
  #     require_sni                    = false
  #   }
  # }

  # # Additional HTTPS listeners with SNI for multiple domains
  # dynamic "http_listener" {
  #   for_each = (var.ssl_certificate_path != "" || var.ssl_certificate_data != "") ? var.additional_hostnames : []
  #   content {
  #     name                           = "${var.project}-https-listener-${http_listener.key}"
  #     frontend_ip_configuration_name = "${var.project}-frontend-ip"
  #     frontend_port_name             = "https-port"
  #     protocol                       = "Https"
  #     ssl_certificate_name           = var.ssl_certificate_path != "" ? "${var.project}-ssl-cert" : "${var.project}-ssl-cert-data"
  #     host_name                      = http_listener.value
  #     require_sni                    = true
  #   }
  # }

  # # HTTP to HTTPS redirect rule (only if SSL is configured)
  # dynamic "redirect_configuration" {
  #   for_each = var.ssl_certificate_path != "" || var.ssl_certificate_data != "" ? [1] : []
  #   content {
  #     name                 = "${var.project}-http-to-https-redirect"
  #     redirect_type        = "Permanent"
  #     target_listener_name = "${var.project}-https-listener"
  #     include_path         = true
  #     include_query_string = true
  #   }
  # }

  # Request routing rule - HTTP to HTTPS redirect (if SSL configured) OR HTTP to backend (if no SSL)
  request_routing_rule {
    name                        = "${var.project}-http-routing-rule"
    rule_type                   = "Basic"
    http_listener_name          = "${var.project}-http-listener"
    redirect_configuration_name = var.ssl_certificate_path != "" || var.ssl_certificate_data != "" ? "${var.project}-http-to-https-redirect" : null
    backend_address_pool_name   = var.ssl_certificate_path == "" && var.ssl_certificate_data == "" ? "${var.project}-aks-backend-pool" : null
    backend_http_settings_name  = var.ssl_certificate_path == "" && var.ssl_certificate_data == "" ? "${var.project}-backend-http-settings" : null
    priority                    = 100
  }

  # Request routing rule - HTTPS to backend (only if SSL is configured)
  # dynamic "request_routing_rule" {
  #   for_each = var.ssl_certificate_path != "" || var.ssl_certificate_data != "" ? [1] : []
  #   content {
  #     name                       = "${var.project}-https-routing-rule"
  #     rule_type                  = "Basic"
  #     http_listener_name         = "${var.project}-https-listener"
  #     backend_address_pool_name  = "${var.project}-aks-backend-pool"
  #     backend_http_settings_name = "${var.project}-backend-http-settings"
  #     priority                   = 200
  #   }
  # }

  # Path-based routing rules (optional)
  # dynamic "url_path_map" {
  #   for_each = var.enable_path_based_routing ? [1] : []
  #   content {
  #     name                               = "${var.project}-path-map"
  #     default_backend_address_pool_name  = "${var.project}-aks-backend-pool"
  #     default_backend_http_settings_name = "${var.project}-backend-http-settings"

  #     dynamic "path_rule" {
  #       for_each = var.path_rules
  #       content {
  #         name                       = path_rule.value.name
  #         paths                      = path_rule.value.paths
  #         backend_address_pool_name  = path_rule.value.backend_pool_name
  #         backend_http_settings_name = path_rule.value.backend_settings_name
  #       }
  #     }
  #   }
  # }

  # # WAF configuration (if using WAF tier)
  # dynamic "waf_configuration" {
  #   for_each = var.enable_waf ? [1] : []
  #   content {
  #     enabled                  = true
  #     firewall_mode            = var.waf_mode
  #     rule_set_type            = "OWASP"
  #     rule_set_version         = var.waf_rule_set_version
  #     file_upload_limit_mb     = 100
  #     request_body_check       = true
  #     max_request_body_size_kb = 128
  #   }
  # }

  # Identity for Key Vault access
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity.id]
  }

  # Enable HTTP/2
  # enable_http2 = true

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
      ssl_certificate,
      frontend_port
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