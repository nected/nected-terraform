# Project Variable
variable "project" {
  type        = string
  description = "Project Description"
  default     = "nected"
}

# Environment Variable
variable "environment" {
  type        = string
  description = "Project Environment"
  default     = "dev"
}

# Resource Group Variable
variable "resource_group_name" {
  type        = string
  description = "Azure Resource Group Name"
}

# Hosted Zone Resource Group name
variable "hosted_zone_rg" {
  type        = string
  description = "Azure Resource Group Name for Hosted Zone"
  default     = "null"
}

# Network Varibales.
# VNet Variables
variable "existing_subnets" {
  description = "Map of subnet names to existing subnet IDs. If provided, the existing subnet will be used instead of creating a new one."
  type        = map(string)
  default     = {}
}

variable "existing_vnet_name" {
  description = "Name of an existing VNet to use. If empty, a new VNet will be created."
  type        = string
  default     = ""
}

variable "vnet_address_space" {
  type        = string
  description = "The address space of the VNet"
  default     = "10.50.0.0/16"
}

variable "private_subnets" {
  description = "List of subnet roles that should have private endpoint configured. Not required for existing vnet"
  type        = list(string)
  default     = ["psql", "redis", "private"]
}

# # Subscription Variables
variable "subscription_id" {
  type        = string
  description = "Subscription ID"
}

# AKS Variables
variable "kubernetes_version" {
  type    = string
  default = "1.33"
}

variable "aks_node_count" {
  type    = number
  default = 2
}

variable "aks_min_node_count" {
  type    = number
  default = 2
}

variable "aks_max_node_count" {
  type    = number
  default = 4
}
variable "aks_vm_size" {
  type        = string
  description = "AKS VM Size"
  default     = "Standard_D4ds_v6"
}

variable "aks_private_cluster_enabled" {
  type        = bool
  description = "Enable private cluster for AKS. When true, the API server is only accessible from within the VNet. Change to true only if you're connected via VPN or a jump box in the VNet"
  default     = false
}

# Postgresql Variables
variable "pg_version" {
  type        = number
  description = "Posgresql Version"
  default     = 17
}

variable "pg_admin_user" {
  type        = string
  description = "Posgresql Admin User"
  default     = "psqladmin"
}

variable "pg_admin_passwd" {
  type        = string
  description = "Posgresql Admin Password"
}

variable "pg_sku_name" {
  type        = string
  description = "Posgresql SKU Name"
  default     = "GP_Standard_D4ds_v5"
}

variable "pg_disk_size" {
  type        = number
  description = "Posgresql Disk Size"
  default     = 262144
}

variable "pg_backup_retention" {
  type        = number
  description = "Posgresql Backup retention in days"
  default     = 7
}

# Redis Variables
variable "redis_capacity" {
  type        = number
  description = "Redis Cache capacity"
  default     = 1
}

variable "use_managed_redis" {
  type        = bool
  description = "Azure Provided managed redis, if set false redis will be installed in aks cluster"
  default     = false
}

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
    condition     = contains([0, 3, 5, 7], var.cassandra_node_count)
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

variable "agic_internal" {
  type        = bool
  description = "Application gateway internal"
  default     = false
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "key_vault_name" {
  type        = string
  description = "Key Vault Name"
  default     = "null"
}

variable "key_vault_certificate_name" {
  type        = string
  description = "Key Vault Secrets name for certificate"
  default     = "null"
}

variable "az_hosted_zone" {
  type        = bool
  description = "When false, DNS entry and cert-manager certificate will not be created."
  default     = true

  validation {
    condition     = !(var.key_vault_name == "null" && var.az_hosted_zone == false)
    error_message = <<-EOT
      SSL certificate configuration is missing.
      Nected services require a valid SSL certificate, which must be provided via one of:
        - A hosted zone via cert manager (set az_hosted_zone = true, and valid hosted zone with base_domain)
        - An existing Key Vault certificate (set key_vault_name, and key_vault_certificate_name)
      Current state: key_vault_name is "null" and az_hosted_zone is false — no certificate source defined.
    EOT
  }
}

variable "base_domain" {
  type        = string
  description = "base domain"
}

# App Domains Variables
variable "router_domain" {
  type        = string
  description = "Router Domain"
}

variable "backend_domain" {
  type        = string
  description = "Backend Domain"
}

variable "ui_domain" {
  type        = string
  description = "UI Domain "
}