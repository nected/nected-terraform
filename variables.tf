
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

###############################################
# Cassandra Variables
###############################################
variable "cassandra_node_count" {
  description = "Cassandra Node Count"
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 3, 5, 7], var.cassandra_node_count)
    error_message = "Valid values for cassandra_node_count are (0, 3, 5, 7)."
  }
}

variable "cassandra_data_disk_size_gb" {
  description = "Size of data disk per Cassandra node in GB"
  type        = number
  default     = 256
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

variable "pg_backup_retention" {
  type        = number
  description = "Posgresql Backup retention in days"
  default     = 7
}

# Cache
variable "use_managed_cache" {
  type        = bool
  description = "Azure Provided managed redis, if set false redis will be installed in aks cluster"
  default     = false
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
  default     = "0.4.45"
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

variable "nected_custom_ca" {
  description = "Custom CA configuration mounted into Nected pods"

  type = object({
    enabled    = optional(bool, false)
    secretName = optional(string, "")

    items = optional(list(object({
      key  = string
      path = string
    })), [])

    includeSystemBundle = optional(bool, true)

    trustBundlePaths = optional(
      list(string),
      [
        "/etc/ssl/certs/ca-certificates.crt",
        "/etc/ssl/cert.pem"
      ]
    )

    defaultMode = optional(string, "0444")

    initContainer = optional(object({
      image           = optional(string, "")
      imagePullPolicy = optional(string, "")

      resources = optional(object({
        requests = optional(object({
          cpu    = optional(string)
          memory = optional(string)
        }), {})

        limits = optional(object({
          cpu    = optional(string)
          memory = optional(string)
        }), {})
      }), {})
    }), {})
  })

  default = {}
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

# use application gateway / load balancer private ip
variable "agic_internal" {
  type        = bool
  description = "Application gateway Internal or Public"
  default     = false
}

