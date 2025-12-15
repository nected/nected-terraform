locals {
  subscription_id         = data.azurerm_client_config.current.subscription_id
  resource_group_name     = data.azurerm_resource_group.rg.name
  resource_group_location = data.azurerm_resource_group.rg.location
  hosted_zone_rg          = var.hosted_zone_rg == "null" ? local.resource_group_name : var.hosted_zone_rg

  subnets = {
    psql = {
      address_prefixes = cidrsubnet(var.vnet_address_space, 8, 1)
      delegation       = true
      security_rules = [
        {
          port                  = "5432"
          direction             = "Inbound"
          source_address_prefix = var.vnet_address_space
        }
      ]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    },
    # redis = {
    #   address_prefixes = cidrsubnet(var.vnet_address_space, 8, 2)
    #   delegation       = false
    #   security_rules = [
    #     {
    #       port                  = "6379"
    #       direction             = "Inbound"
    #       source_address_prefix = var.vnet_address_space
    #     },
    #     {
    #       port                  = "6380"
    #       direction             = "Inbound"
    #       source_address_prefix = var.vnet_address_space
    #     }
    #   ]
    #   service_endpoints = ["Microsoft.Storage"]
    # },
    aks = {
      address_prefixes = cidrsubnet(var.vnet_address_space, 6, 1)
      delegation       = false
      security_rules = [
        {
          port                  = "443"
          direction             = "Inbound"
          source_address_prefix = "0.0.0.0/0"
        },
        {
          port                  = "0-65535"
          direction             = "Outbound"
          source_address_prefix = "0.0.0.0/0"
        }
      ]
      service_endpoints = ["Microsoft.ContainerRegistry", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.AzureActiveDirectory"]
    }
    private = {
      address_prefixes = cidrsubnet(var.vnet_address_space, 6, 2)
      delegation       = false
      security_rules = [
        {
          port                  = "22"
          direction             = "Inbound"
          source_address_prefix = "0.0.0.0/0"
        },
        {
          port                  = "9200"
          direction             = "Inbound"
          source_address_prefix = var.vnet_address_space
        }
      ]
      service_endpoints = ["Microsoft.ContainerRegistry", "Microsoft.Storage"]
    }
    appgw = {
      address_prefixes  = cidrsubnet(var.vnet_address_space, 8, 3)
      delegation        = false
      service_endpoints = []
    }
  }
}

