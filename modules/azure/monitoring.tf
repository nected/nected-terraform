############################################################
# Azure Monitor: logging, metrics (managed Prometheus) & alerting for AKS
#
#  Layer 1 - Log Analytics workspace + Container Insights (oms_agent in aks.tf)
#            -> container/application logs in the ContainerLogV2 table
#  Layer 2 - Azure Monitor workspace + managed Prometheus (monitor_metrics in
#            aks.tf) with a data-collection rule; optional Managed Grafana
#  Alerting - Action Group (email) + a KQL log alert on error lines and metric
#             alerts on node CPU / memory
############################################################

locals {
  mon_enabled  = var.enable_azure_monitoring ? 1 : 0
  prom_enabled = var.enable_azure_monitoring && var.enable_managed_prometheus ? 1 : 0
  graf_enabled = var.enable_azure_monitoring && var.enable_managed_prometheus && var.enable_managed_grafana ? 1 : 0
  monitoring_tags = {
    Environment = var.environment
    createdby   = "terraform"
  }
}

resource "azurerm_resource_provider_registration" "monitor" {
  count = local.prom_enabled
  name  = "Microsoft.Monitor"
}

resource "azurerm_resource_provider_registration" "dashboard" {
  count = local.graf_enabled
  name  = "Microsoft.Dashboard"
}

# -------------------
# Log Analytics workspace (Container Insights sink)
# -------------------
resource "azurerm_log_analytics_workspace" "main" {
  count               = local.mon_enabled
  name                = "${var.project}-${var.environment}-law"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days
  tags                = local.monitoring_tags

  depends_on = [azurerm_resource_provider_registration.monitor]
}

# -------------------
# Azure Monitor workspace + managed Prometheus data collection
# -------------------
resource "azurerm_monitor_workspace" "prometheus" {
  count               = local.prom_enabled
  name                = "${var.project}-${var.environment}-amw"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  tags                = local.monitoring_tags

  depends_on = [azurerm_resource_provider_registration.monitor]
}

resource "azurerm_monitor_data_collection_endpoint" "prometheus" {
  count               = local.prom_enabled
  name                = "${var.project}-${var.environment}-msprom-dce"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  kind                = "Linux"
  tags                = local.monitoring_tags

  depends_on = [azurerm_resource_provider_registration.monitor]
}

resource "azurerm_monitor_data_collection_rule" "prometheus" {
  count                       = local.prom_enabled
  name                        = "${var.project}-${var.environment}-msprom-dcr"
  location                    = local.resource_group_location
  resource_group_name         = local.resource_group_name
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.prometheus[0].id
  kind                        = "Linux"
  tags                        = local.monitoring_tags

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.prometheus[0].id
      name               = "MonitoringAccount1"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount1"]
  }

  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "PrometheusDataSource"
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "prometheus" {
  count                   = local.prom_enabled
  name                    = "${var.project}-${var.environment}-msprom-dcra"
  target_resource_id      = azurerm_kubernetes_cluster.k8s.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.prometheus[0].id
  description             = "Associate AKS with the managed Prometheus data collection rule"
}

# -------------------
# Azure Managed Grafana (optional) wired to the Monitor workspace
# -------------------
resource "azurerm_dashboard_grafana" "main" {
  count                             = local.graf_enabled
  name                              = "${var.project}-${var.environment}-grafana"
  location                          = local.resource_group_location
  resource_group_name               = local.resource_group_name
  grafana_major_version             = 11
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = false
  public_network_access_enabled     = true
  tags                              = local.monitoring_tags

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.prometheus[0].id
  }
}

# Grafana's managed identity needs to read metrics from the Monitor workspace
resource "azurerm_role_assignment" "grafana_monitoring_reader" {
  count                = local.graf_enabled
  scope                = azurerm_monitor_workspace.prometheus[0].id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_dashboard_grafana.main[0].identity[0].principal_id
}

# -------------------
# Alerting: Action Group (email)
# -------------------
resource "azurerm_monitor_action_group" "alerts" {
  count               = local.mon_enabled
  name                = "${var.project}-${var.environment}-alerts"
  resource_group_name = local.resource_group_name
  short_name          = substr("${var.project}${var.environment}", 0, 12)
  tags                = local.monitoring_tags

  dynamic "email_receiver" {
    for_each = toset(var.monitoring_alert_emails)
    content {
      name                    = "email-${replace(email_receiver.value, "/[^a-zA-Z0-9]/", "-")}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }
}

# -------------------
# Log alert: application error lines in container logs
# -------------------
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "app_errors" {
  count                = local.mon_enabled
  name                 = "${var.project}-${var.environment}-high-app-errors"
  location             = local.resource_group_location
  resource_group_name  = local.resource_group_name
  description          = "Container error log lines exceeded ${var.app_error_alert_threshold} in 5 minutes"
  severity             = 2
  scopes               = [azurerm_log_analytics_workspace.main[0].id]
  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"
  tags                 = local.monitoring_tags

  criteria {
    query                   = <<-KQL
      ContainerLogV2
      | where LogMessage has_any ("error", "Error", "ERROR", "exception", "Exception", "panic", "fatal", "FATAL")
    KQL
    time_aggregation_method = "Count"
    threshold               = var.app_error_alert_threshold
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.alerts[0].id]
  }
}

# -------------------
# Metric alerts: AKS node CPU / memory (platform metrics)
# -------------------
resource "azurerm_monitor_metric_alert" "node_cpu_high" {
  count               = local.mon_enabled
  name                = "${var.project}-${var.environment}-node-cpu-high"
  resource_group_name = local.resource_group_name
  scopes              = [azurerm_kubernetes_cluster.k8s.id]
  description         = "AKS node CPU above ${var.node_cpu_alert_threshold}%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = local.monitoring_tags

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.node_cpu_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.alerts[0].id
  }
}

resource "azurerm_monitor_metric_alert" "node_memory_high" {
  count               = local.mon_enabled
  name                = "${var.project}-${var.environment}-node-memory-high"
  resource_group_name = local.resource_group_name
  scopes              = [azurerm_kubernetes_cluster.k8s.id]
  description         = "AKS node working-set memory above ${var.node_memory_alert_threshold}%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = local.monitoring_tags

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.node_memory_alert_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.alerts[0].id
  }
}
