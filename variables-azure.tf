##################################
###### Azure Variables ###########
##################################
# # Subscription Variables
variable "az_subscription_id" {
  type        = string
  description = "Subscription ID"
}
# Resource Group Variable
variable "az_resource_group_name" {
  type        = string
  description = "Azure Resource Group Name"
}

# Hosted Zone Resource Group name
variable "az_hosted_zone_rg" {
  type        = string
  description = "Azure Resource Group Name for Hosted Zone"
  default     = "null"
}
# Network Varibales.
# VNet Variables
variable "az_existing_subnets" {
  description = "Map of subnet names to existing subnet IDs. If provided, the existing subnet will be used instead of creating a new one."
  type        = map(string)
  default     = {}
}

variable "az_existing_network_name" {
  description = "Name of an existing Network(VPC/Vnet) to use. If empty, a new VNet/VPC will be created."
  type        = string
  default     = ""
}

variable "network_address_space" {
  type        = string
  description = "The address space of the Network(VPC/Vnet)"
  default     = "10.50.0.0/16"
}

variable "az_private_subnets" {
  description = "List of subnet roles that should have private endpoint configured. Not required for existing vnet"
  type        = list(string)
  default     = ["psql", "redis", "private"]
}

# AKS
variable "aks_vm_size" {
  type        = string
  description = "AKS VM Size"
  default     = "Standard_D4ds_v6"
}
variable "aks_private_cluster_enabled" {
  type        = bool
  description = "Enable private cluster for Kubernetes. When true, the API server is only accessible from within the Network. Change to true only if you're connected via VPN or a jump box in the Network"
  default     = false
}

# Cache/redis

# Redis Variables
variable "az_redis_capacity" {
  type        = number
  description = "Redis Cache capacity"
  default     = 1
}

# ElasticSearch
# Elasticsearch Variables
variable "elasticsearch_version" {
  type        = string
  description = "Elasticsearch Version"
  default     = "8.12.0"
}

variable "elasticsearch_vm_size" {
  type        = string
  description = "Elasticsearch VM Size"
  default     = "Standard_D2ds_v4"
}

variable "elasticsearch_admin_username" {
  type        = string
  description = "Elasticsearch Admin Username"
  default     = "elastic"
}

variable "elasticsearch_admin_password" {
  type        = string
  description = "Elasticsearch Admin Password"
}


variable "elasticsearch_os_disk_size_gb" {
  type        = number
  description = "ElasticSearch OS Disk size"
  default     = 256
}

# Cassandra Variables
variable "cassandra_node_count" {
  description = "Cassandra Node Count"
  type        = number
  default     = 0

  validation {
    condition     = var.cloud_provider != "azure" || contains([0, 3, 5, 7], var.cassandra_node_count)
    error_message = "Valid values for cassandra_node_count are (0, 3, 5, 7)."
  }
}

variable "cassandra_vm_size" {
  description = "Azure VM SKU for Cassandra nodes. Standard_D4as_v5 = 4 vCPU / 16GB RAM. Use Standard_A4_v2 for strict 4c/8GB (not recommended for prod)."
  type        = string
  default     = "Standard_D4as_v5"
}

variable "cassandra_admin_password" {
  description = "SSH admin password for Cassandra VMs"
  type        = string
  default     = "Cassandra#123"
}

variable "cassandra_admin_username" {
  description = "SSH admin username for Cassandra VMs"
  type        = string
  default     = "cassandra"
}

variable "cassandra_data_disk_size_gb" {
  description = "Size of data disk per Cassandra node in GB"
  type        = number
  default     = 256
}

# Postgresql
variable "az_pg_disk_size" {
  type        = number
  description = "Posgresql Disk Size"
  default     = 262144
}

variable "az_pg_sku_name" {
  type        = string
  description = "Posgresql SKU Name"
  default     = "GP_Standard_D4ds_v5"
}

# Application Gateway Variables

# SSL key vault
variable "az_key_vault_name" {
  type        = string
  description = "Key Vault Name"
  default     = "null"
}

variable "az_key_vault_certificate_name" {
  type        = string
  description = "Key Vault Secrets name for certificate"
  default     = "null"
}

variable "az_hosted_zone" {
  type        = bool
  description = "When false, DNS entry and cert-manager certificate will not be created."
  default     = true

  validation {
    condition     = var.cloud_provider != "azure" || !(var.az_key_vault_name == "null" && var.az_hosted_zone == false)
    error_message = <<-EOT
      SSL certificate configuration is missing.
      Nected services require a valid SSL certificate, which must be provided via one of:
        - A hosted zone via cert manager (set az_hosted_zone = true, and valid hosted zone with base_domain)
        - An existing Key Vault certificate (set az_key_vault_name, and key_vault_certificate_name)
      Current state: az_key_vault_name is "null" and az_hosted_zone is false — no certificate source defined.
    EOT
  }
}


# Application Gateway SKU Configuration
variable "appgw_sku_name" {
  type        = string
  description = "The SKU name of the Application Gateway"
  default     = "Standard_v2"
}

variable "appgw_sku_tier" {
  type        = string
  description = "The SKU tier of the Application Gateway"
  default     = "Standard_v2"
}

variable "appgw_capacity" {
  type        = number
  description = "The capacity (instance count) of the Application Gateway"
  default     = 2
}

# Autoscaling Configuration
variable "enable_autoscaling" {
  type        = bool
  description = "Enable autoscaling for Application Gateway"
  default     = true
}

variable "appgw_min_capacity" {
  type        = number
  description = "Minimum capacity for autoscaling"
  default     = 2
}

variable "appgw_max_capacity" {
  type        = number
  description = "Maximum capacity for autoscaling"
  default     = 10
}

# Health Probe Configuration
variable "health_probe_path" {
  type        = string
  description = "Path for health probe"
  default     = "/"
}

variable "health_probe_host" {
  type        = string
  description = "Host header for health probe"
  default     = ""
}

# WAF Configuration
variable "enable_waf" {
  type        = bool
  description = "Enable Web Application Firewall"
  default     = false
}

variable "waf_mode" {
  type        = string
  description = "WAF mode: Detection or Prevention"
  default     = "Detection"
}

variable "waf_rule_set_version" {
  type        = string
  description = "WAF rule set version"
  default     = "3.2"
}

variable "az_helm_disable_openapi_validation" {
  type        = bool
  description = "Skip client-side OpenAPI validation for Nected helm release on AKS. AKS API server often times out serving OpenAPI after large CRDs (cert-manager, temporal) are installed."
  default     = true
}

variable "waf_custom_rules" {
  type = list(object({
    name      = string
    priority  = number
    rule_type = string
    action    = string
    match_conditions = list(object({
      match_variables = list(object({
        variable_name = string
        selector      = optional(string)
      }))
      operator           = string
      negation_condition = optional(bool, false)
      match_values       = list(string)
    }))
  }))
  description = "List of WAF custom rules for the Application Gateway"
  default     = []
}