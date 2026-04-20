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

# services helm charts versions
variable "temporal_chart_version" {
  type        = string
  description = "Temporal Helm Chart Version"
  default     = "0.54.2"
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

# App resources & autoscaling
# temporal replicas and resources
variable "temporal_task_partitions" {
  type        = number
  description = "Temporal tasks partitions"
  default     = 5
}

variable "temporal_history_shards" {
  type        = number
  description = "Temporal History Shards"
  default     = 512
}

variable "temporal_pods_replicas" {
  description = "Temporal auto scaling and replicas"
  type = object({
    autoscaling  = optional(bool, true)
    history      = optional(number, 2)
    min_frontend = optional(number, 2)
    min_matching = optional(number, 2)
    min_worker   = optional(number, 2)
    max_frontend = optional(number, 4)
    max_matching = optional(number, 4)
    max_worker   = optional(number, 4)
  })
  default = {}
}

variable "temporal_pods_resources" {
  description = "Temporal pods resource requests and limits - limits only applied when set"
  type = object({
    # frontend
    frontend_cpu_request    = optional(string, "200m")
    frontend_memory_request = optional(string, "256Mi")
    frontend_cpu_limit      = optional(string, null)
    frontend_memory_limit   = optional(string, null)
    # history
    history_cpu_request    = optional(string, "512m")
    history_memory_request = optional(string, "1024Mi")
    history_cpu_limit      = optional(string, null)
    history_memory_limit   = optional(string, null)
    # matching
    matching_cpu_request    = optional(string, "200m")
    matching_memory_request = optional(string, "256Mi")
    matching_cpu_limit      = optional(string, null)
    matching_memory_limit   = optional(string, null)
    # worker
    worker_cpu_request    = optional(string, "200m")
    worker_memory_request = optional(string, "256Mi")
    worker_cpu_limit      = optional(string, null)
    worker_memory_limit   = optional(string, null)
    # schema
    schema_job_cpu_request    = optional(string, null)
    schema_job_memory_request = optional(string, null)
    schema_job_cpu_limit      = optional(string, null)
    schema_job_memory_limit   = optional(string, null)
  })
  default = {}
}

# nected resources and replicas
variable "nected_enable_garuda" {
  type    = bool
  default = false
}

variable "nected_pods_resources" {
  description = "Nected pods resource requests and limits - limits only applied when set"
  type = object({
    # konark
    konark_cpu_request    = optional(string, "200m")
    konark_memory_request = optional(string, "256Mi")
    konark_cpu_limit      = optional(string, null)
    konark_memory_limit   = optional(string, null)
    # nalanda
    nalanda_cpu_request    = optional(string, "200m")
    nalanda_memory_request = optional(string, "256Mi")
    nalanda_cpu_limit      = optional(string, null)
    nalanda_memory_limit   = optional(string, null)
    # vidhaan-executer
    executer_cpu_request    = optional(string, "250m")
    executer_memory_request = optional(string, "512Mi")
    executer_cpu_limit      = optional(string, null)
    executer_memory_limit   = optional(string, null)
    # vidhaan-router
    router_cpu_request    = optional(string, "200m")
    router_memory_request = optional(string, "256Mi")
    router_cpu_limit      = optional(string, null)
    router_memory_limit   = optional(string, null)
    # medha
    medha_cpu_request    = optional(string, "500m")
    medha_memory_request = optional(string, "1024Mi")
    medha_cpu_limit      = optional(string, null)
    medha_memory_limit   = optional(string, null)
    # garuda
    garuda_cpu_request    = optional(string, "500m")
    garuda_memory_request = optional(string, "1024Mi")
    garuda_cpu_limit      = optional(string, null)
    garuda_memory_limit   = optional(string, null)
    # setup job
    setup_job_cpu_request    = optional(string, null)
    setup_job_memory_request = optional(string, null)
    setup_job_cpu_limit      = optional(string, null)
    setup_job_memory_limit   = optional(string, null)
    # setup job
    secret_job_cpu_request    = optional(string, null)
    secret_job_memory_request = optional(string, null)
    secret_job_cpu_limit      = optional(string, null)
    secret_job_memory_limit   = optional(string, null)
  })
  default = {}
}

variable "nected_pods_replicas" {
  description = "Nected auto-scaling and replicas"
  type = object({
    autoscaling  = optional(bool, true)
    min_nalanda  = optional(number, 2)
    min_executer = optional(number, 2)
    min_router   = optional(number, 2)
    min_medha    = optional(number, 1)
    min_garuda   = optional(number, 1)
    max_nalanda  = optional(number, 3)
    max_executer = optional(number, 6)
    max_router   = optional(number, 4)
    max_medha    = optional(number, 2)
    max_garuda   = optional(number, 2)
  })
  default = {}
}

# Nected license pre shared key
variable "nected_pre_shared_key" {
  type    = string
  default = "1182d659-8c9b-4541-90ac-8546372c326f"
}

# App Domains Variables
variable "scheme" {
  type        = string
  description = "Scheme"
  default     = "https"
}

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

# Nected app env configuration variables
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

variable "nected_existing_secret_name" {
  type        = string
  description = "Nected services env secret name"
  default     = ""
}

variable "nected_common_secret_value" {
  type        = string
  description = "Nected services common secret value"
  default     = ""
}

variable "nected_env_overrides" {
  type        = map(map(string))
  description = "nalanda services envVars keys"
  default = {
    "konark"  = {}
    "nalanda" = {}
    "vidhaan" = {}
    "medha"   = {}
    "garuda"  = {}
  }
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
