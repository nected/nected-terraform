locals {
  subscription_id            = data.azurerm_client_config.current.subscription_id
  resource_group_name        = data.azurerm_resource_group.rg.name
  resource_group_location    = data.azurerm_resource_group.rg.location
  hosted_zone_rg             = var.hosted_zone_rg == "null" ? local.resource_group_name : var.hosted_zone_rg
  temporal_persistant_driver = var.cassandra_node_count != 0 ? "cassandra" : "sql"

  vnet_name = var.existing_vnet_name != "" ? data.azurerm_virtual_network.existing[0].name : azurerm_virtual_network.prod[0].name

  vnet_id = var.existing_vnet_name != "" ? data.azurerm_virtual_network.existing[0].id : azurerm_virtual_network.prod[0].id

  subnets_to_create = {
    for name, subnet in local.subnets : name => subnet
    if var.existing_vnet_name == ""
  }

  nsg_to_create = {
    for name, subnet in local.subnets : name => subnet
    if lookup(subnet, "security_rules", null) != null
  }

  subnets_to_private = {
    for name, subnet in local.subnets_to_create : name => subnet
    if contains(var.private_subnets, name) && var.existing_vnet_name == ""
  }

  subnets_to_lookup = var.existing_vnet_name != "" ? var.existing_subnets : {}

  # NAT Gateway needed only when there are private subnets being created
  create_nat_gateway = length(local.subnets_to_private) > 0 && var.existing_vnet_name == ""

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
    redis = {
      address_prefixes = cidrsubnet(var.vnet_address_space, 8, 2)
      delegation       = false
      security_rules = [
        {
          port                  = "6379"
          direction             = "Inbound"
          source_address_prefix = var.vnet_address_space
        },
        {
          port                  = "6380"
          direction             = "Inbound"
          source_address_prefix = var.vnet_address_space
        }
      ]
      service_endpoints = ["Microsoft.Storage"]
    },
    aks = {
      address_prefixes = cidrsubnet(var.vnet_address_space, 6, 1)
      delegation       = false
      security_rules = [
        {
          port                  = "443"
          direction             = "Inbound"
          source_address_prefixes = var.allowed_aks_cidrs
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
          source_address_prefix = var.vnet_address_space
        },
        {
          port                  = "9200"
          direction             = "Inbound"
          source_address_prefix = var.vnet_address_space
        },
        {
          port                  = "9042"
          direction             = "Inbound"
          source_address_prefix = var.vnet_address_space
        },
        {
          port                  = "7000"
          direction             = "Inbound"
          source_address_prefix = var.vnet_address_space
        },
        {
          port                  = "7199"
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
      security_rules = [
        {
          port                  = "443"
          direction             = "Inbound"
          source_address_prefixes = var.allowed_gw_cidrs
        },
        {
          port                  = "65200-65535"
          direction             = "Inbound"
          source_address_prefix = "Internet"
        }
      ]
      service_endpoints = ["Microsoft.KeyVault"]
    }
  }

  # IPs and DNS mapping
  internal_app_gateway_ip = var.existing_vnet_name != "" ? cidrhost(data.azurerm_subnet.existing["appgw"].address_prefixes[0], 5) : cidrhost(local.subnets.appgw.address_prefixes, 5)
  dns_record_ip           = var.agic_internal ? local.internal_app_gateway_ip : azurerm_public_ip.appgw_pip.ip_address

  redis_tls_enabled = var.use_managed_redis ? "true" : "false"
  redis_endpoint    = var.use_managed_redis ? azurerm_redis_cache.redis[0].hostname : "datastore-redis-master"
  redis_port        = var.use_managed_redis ? "6380" : "6379"
  redis_password    = var.use_managed_redis ? azurerm_redis_cache.redis[0].primary_access_key : ""


  cert_secret_name          = "${var.project}-tls-${var.environment}"
  cert_vault_name           = "${var.project}-vault-${var.environment}"
  key_vault_id              = var.key_vault_name == "null" ? azurerm_key_vault.ssl_certs_vault[0].id : data.azurerm_key_vault.vault[0].id
  alb_vault_secret_endpoint = var.key_vault_name == "null" ? "https://${azurerm_key_vault.ssl_certs_vault[0].name}.vault.azure.net/secrets/${local.cert_secret_name}" : "https://${var.key_vault_name}.vault.azure.net/secrets/${var.key_vault_certificate_name}"
}
