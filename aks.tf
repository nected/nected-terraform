# AKS
resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "${var.project}-aks"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  dns_prefix          = var.project
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                 = "default"
    node_count           = var.aks_node_count
    vm_size              = var.aks_vm_size
    vnet_subnet_id       = azurerm_subnet.subnets["aks"].id
    min_count            = var.aks_min_node_count
    max_count            = var.aks_max_node_count
    auto_scaling_enabled = true
    max_pods             = 110
    os_disk_size_gb      = 128
    type                 = "VirtualMachineScaleSets"

    upgrade_settings {
      max_surge = "10%"
    }
  }

  network_profile {
    network_plugin    = "azure"
    dns_service_ip    = "10.2.0.10"
    service_cidr      = "10.2.0.0/24"
    load_balancer_sku = "standard"
  }

  identity {
    type = "SystemAssigned"
  }
  azure_policy_enabled = true

  # enable workload identity
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  tags = {
    Environment = var.environment
    createdby   = "terraform"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool
    ]
  }

  depends_on = [azurerm_virtual_network.prod]
}