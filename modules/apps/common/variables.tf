# services helm charts versions
variable "temporal_chart_version" {
  type        = string
  description = "Temporal Helm Chart Version"
  default     = "0.54.2"
}

variable "temporal_cluster_name" {
  type        = string
  description = "Temporal Cluster Name"
  default     = "nected-temporal"
}

variable "temporal_persistant_driver" {
  type        = string
  description = "Temporal Persistant Driver"
  default     = "sql"
}

variable "postgresql_host" {
  
}

variable "pg_admin_user" {
  type        = string
  description = "Postgresql DB admin User"
  default     = ""
}

variable "pg_admin_passwd" {
  type        = string
  description = "Postgresql DB admin Password"
  default     = ""
}

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

variable "seed_node_list" {
  type        = list(string)
  description = "Cassandra seed node list"
  default     = []
}

variable "elasticsearch_admin_username" {
  type        = string
  description = "Elasticsearch Admin User"
  default     = ""
}

variable "elasticsearch_admin_password" {
  type        = string
  description = "Elasticsearch Admin Password"
  default     = ""
}

########
variable "nected_chart_version" {
  type        = string
  description = "Nected Helm Chart Version"
  default     = "0.4.35"
}

variable "scheme" {
  type        = string
  description = "Scheme http/https"
  default     = "https"
}

variable "nected_existing_secret_name" {
  type        = string
  description = "Nected services env secret name"
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

variable "nected_common_secret_value" {
  type        = string
  description = "Nected services common secret value"
  default     = ""
}

variable "ingress_use_private" {
  type        = bool
  description = "Private Ingress(Load Balancer)"
  default     = false
}

variable "ingress_annotations" {
  type        = map(any)
  description = "Ingress annotation for load balancer/app gateway"
}
variable "nected_pre_shared_key" {
  type        = string
  description = "Pre-shared key used for authentication between Nected components"
}

variable "console_user_email" {
  type        = string
  description = "Email address for the console user account"
}

variable "console_user_password" {
  type        = string
  description = "Password for the console user account"
}

variable "ui_domain" {
  type        = string
  description = "Domain name for the UI service"
}

variable "backend_domain" {
  type        = string
  description = "Domain name for the backend service"
}

variable "router_domain" {
  type        = string
  description = "Domain name for the router service"
}

variable "use_managed_redis" {
  type        = bool
  description = "Azure Provided managed redis, if set false redis will be installed in aks cluster"
  default     = false
}

variable "redis_tls_enabled" {
  type        = string
  description = "Enable or disable TLS for Redis (expected values: \"true\" or \"false\")"
}

variable "redis_endpoint" {
  type        = string
  description = "Hostname or IP address of the Redis instance"
}

variable "redis_port" {
  type        = string
  description = "Port number on which Redis is accessible"
}

variable "redis_password" {
  type        = string
  description = "Password used to authenticate with Redis"
}

variable "datastore_chart_version" {
  type        = string
  description = "Datastore Helm Chart Version"
  default     = "0.1.2"
}

variable "elasticsearch_ip" {
}

variable "namespace" {
  type = string
  default = "default"
  description = "K8s Namespace"
}