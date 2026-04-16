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
  description = "List of subnet roles that should have private endpoint configured."
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
  default = "1.32"
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
  default = 5
}
variable "aks_vm_size" {
  type        = string
  description = "AKS VM Size"
  default     = "Standard_D4ds_v6"
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
  description = "Azure Provided managed redis"
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

# App resources & autoscaling
variable "temporal_task_partitions" {
  type        = number
  description = "Temporal tasks partitions"
  default     = 20
}
variable "temporal_service_autoscale" {
  type        = bool
  description = "Temporal Service Autoscale"
  default     = true
}
variable "temporal_history_pods" {
  type        = number
  description = "Temporal History Pods"
  default     = 2
}

variable "temporal_min_frontend_pods" {
  type        = number
  description = "Temporal Frontend Min Pods"
  default     = 2
}

variable "temporal_min_matching_pods" {
  type        = number
  description = "Temporal Matching Min Pods"
  default     = 2
}

variable "temporal_min_worker_pods" {
  type        = number
  description = "Temporal Worker Min Pods"
  default     = 1
}
variable "temporal_max_frontend_pods" {
  type        = number
  description = "Temporal Frontend Max Pods"
  default     = 4
}

variable "temporal_max_matching_pods" {
  type        = number
  description = "Temporal Matching Max Pods"
  default     = 4
}

variable "temporal_max_worker_pods" {
  type        = number
  description = "Temporal Worker Max Pods"
  default     = 4
}

variable "temporal_chart_version" {
  type        = string
  description = "Temporal Helm Chart Version"
  default     = "0.54.0"
}

variable "nected_service_autoscale" {
  type        = bool
  description = "Nected Service Autoscale"
  default     = true
}

variable "nected_min_nalanda_pods" {
  type        = number
  description = "Nected Nalanda Min Pods"
  default     = 2
}

variable "nected_min_executer_pods" {
  type        = number
  description = "Nected Executer Min Pods"
  default     = 2
}

variable "nected_min_router_pods" {
  type        = number
  description = "Nected Router Min Pods"
  default     = 2
}

variable "nected_min_medha_pods" {
  type        = number
  description = "Nected Medha Min Pods"
  default     = 1
}

variable "nected_max_nalanda_pods" {
  type        = number
  description = "Nected Nalanda Max Pods"
  default     = 3
}

variable "nected_max_executer_pods" {
  type        = number
  description = "Nected Executer Max Pods"
  default     = 6
}

variable "nected_max_router_pods" {
  type        = number
  description = "Nected Router Max Pods"
  default     = 4
}

variable "nected_max_medha_pods" {
  type        = number
  description = "Nected Medha Max Pods"
  default     = 2
}

variable "nected_chart_version" {
  type        = string
  description = "Nected Helm Chart Version"
  default     = "0.4.35"
}

variable "datastore_chart_version" {
  type        = string
  description = "Datastore Helm Chart Version"
  default     = "0.1.2"
}

# App Domains Variables
variable "router_domain_prefix" {
  type        = string
  description = "Router Domain Prefix"
  default     = "router"
}

variable "backend_domain_prefix" {
  type        = string
  description = "Backend Domain Prefix"
  default     = "backend"
}

variable "ui_domain_prefix" {
  type        = string
  description = "UI Domain prefix"
  default     = "ui"
}

variable "scheme" {
  type        = string
  description = "Scheme"
  default     = "https"
}

variable "console_signup_domains" {
  type        = string
  description = "Console Signup Domains Restriction"
  default     = ""
}

variable "console_user_email" {
  type        = string
  description = "Console User Email"
  default     = "dev@nected.ai"
}

variable "console_user_password" {
  type        = string
  description = "Console User Password"
  default     = "P@ssw0rd#123"
}

# SMTP Configuration
variable "smtp_config" {
  type = map(string)
}

# Services Base Domain
variable "base_domain" {
  type        = string
  description = "Enter Base Domain for services"
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "nected_pre_shared_key" {
  type    = string
  default = "1182d659-8c9b-4541-90ac-8546372c326f"
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
