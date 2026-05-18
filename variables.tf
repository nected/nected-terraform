
####################################
######### Common Variables #########
####################################
variable "cloud_provider" {
  description = "Provide the cloud where nected needs to deploy"
  type        = string
  default     = "aws"

  validation {
    condition     = contains(["aws", "azure"], var.cloud_provider)
    error_message = "cloud_provider must be aws or azure"
  }
}

variable "app" {
  type        = bool
  description = "Deploy Apps"
  default     = false
}

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

###################################
###### Kubernetes Variables #######
###################################
variable "k8s_version" {
  type    = string
  default = "1.33"
}

variable "k8s_node_count" {
  type    = number
  default = 2
}

variable "k8s_min_node_count" {
  type    = number
  default = 2
}

variable "k8s_max_node_count" {
  type    = number
  default = 5
}

variable "k8s_private_cluster_enabled" {
  type        = bool
  description = "Enable private cluster for Kubernetes. When true, the API server is only accessible from within the Network. Change to true only if you're connected via VPN or a jump box in the Network"
  default     = false
}

# Cache
variable "use_managed_cache" {
  type        = bool
  description = "Azure Provided managed redis, if set false redis will be installed in aks cluster"
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
  default     = "postgres"
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



variable "pg_backup_retention" {
  type        = number
  description = "Posgresql Backup retention in days"
  default     = 7
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

variable "base_domain" {
  type        = string
  description = "base domain"
}

variable "namespace" {
  type    = string
  default = "default"
}

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
    condition     = !(var.az_key_vault_name == "null" && var.az_hosted_zone == false)
    error_message = <<-EOT
      SSL certificate configuration is missing.
      Nected services require a valid SSL certificate, which must be provided via one of:
        - A hosted zone via cert manager (set az_hosted_zone = true, and valid hosted zone with base_domain)
        - An existing Key Vault certificate (set az_key_vault_name, and key_vault_certificate_name)
      Current state: az_key_vault_name is "null" and az_hosted_zone is false — no certificate source defined.
    EOT
  }
}


#
# Application Gateway Variables

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

variable "agic_internal" {
  type        = bool
  description = "Application gateway Internal or Public"
  default     = false
}

variable "aws_certificate_arn" {
  type        = string
  description = "AWS Certificate Manager - Cert ARN"
}
