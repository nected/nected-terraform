#####################################
######### Project Variables #########
#####################################
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

#####################################
##### CloudWatch Observability ######
#####################################
variable "enable_cloudwatch_logging" {
  type        = bool
  description = "Enable CloudWatch container/application logging and alerting"
  default     = false
}

variable "eks_log_retention_days" {
  type        = number
  description = "Retention (days) for the EKS control plane log group"
  default     = 7
}

variable "app_log_retention_days" {
  type        = number
  description = "Retention (days) for Container Insights log groups"
  default     = 30
}

variable "alert_emails" {
  type        = list(string)
  description = "Emails subscribed to the CloudWatch alerts SNS topic"
  default     = []
}

variable "app_error_alarm_threshold" {
  type        = number
  description = "Error log lines per period that trigger the app error alarm"
  default     = 10
}

variable "eks_control_plane_log_types" {
  type        = list(string)
  description = "EKS control plane log types to ship to CloudWatch"
  default     = ["api", "authenticator"]
}

################################
####### AWS Variables ##########
################################
variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "ap-south-1"
}

variable "aws_profile" {
  type        = string
  description = "AWS Profile"
  default     = "default"
}

variable "route53_hosted_zone" {
  type        = bool
  description = "When false, DNS entry and ACM certificate will not be created."
  default     = true
}

variable "aws_certificate_arn" {
  type        = string
  description = "AWS Certificate Manager - Cert ARN"
  default     = ""

  validation {
    condition     = length(trimspace(var.aws_certificate_arn)) > 0 || var.route53_hosted_zone
    error_message = "aws_certificate_arn must not be empty or route53 hosted zone should be available to generate certificate"
  }
}

######################################
######### App Main Variables #########
######################################
# Nected license key
# VIDHAAN_PRE_SHARED_KEY is the licence key. Not generated: a random value
# would not be a valid licence. The default is the demo licence the charts
# ship; replace the real one in the vault item <name_prefix>/license (see
# secrets.tf), not here.
variable "nected_pre_shared_key" {
  type    = string
  default = "1182d659-8c9b-4541-90ac-8546372c326f"
}

# App Domains Variables
variable "base_domain" {
  type        = string
  description = "base domain"
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
variable "console_user_email" {
  type        = string
  description = "Console User Email"
  default     = "dev@nected.ai"
}

variable "console_user_password" {
  type        = string
  description = "Console User Password"
  default     = null
}

####################################
####### Network Variables ##########
####################################

variable "existing_vpc_id" {
  type        = string
  description = "Existing VPC Name"
  default     = "null"
}

variable "existing_private_subnets" {
  type        = list(string)
  description = "Existing Private Subnets"
  default     = []
}
variable "existing_database_subnets" {
  type        = list(string)
  description = "Existing DB Private Subnets"
  default     = []
}

variable "existing_public_subnets" {
  type        = list(string)
  description = "Existing DB Public Subnets"
  default     = []
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = list(string)
  default     = ["10.0.0.0/16"]

  validation {
    condition     = var.existing_vpc_id != "null" || length(var.vpc_cidr) == 1
    error_message = "You can Only Provide Single CIDR with New VPC"
  }
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.azs) > 0
    error_message = "provide at least one availability zone in var.azs"
  }

  validation {
    condition     = alltrue([for az in var.azs : startswith(az, var.aws_region)])
    error_message = "every AZ in var.azs must belong to var.aws_region (e.g., ${var.aws_region}a)"
  }
}

variable "subnet_newbits" {
  description = "How many bits to add to the VPC prefix per subnet"
  type        = map(number)
  default = {
    public  = 8
    private = 6
    db      = 10
  }
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway"
  type        = bool
  default     = true
}

###################################
###### Kubernetes Variables #######
###################################
variable "k8s_version" {
  type    = string
  default = "1.35"
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

variable "allowed_k8s_cidrs" {
  type        = list(string)
  description = "Allowed CIDRS"
  default     = ["0.0.0.0/0"]
}

variable "eks_node_instance_types" {
  type        = list(string)
  description = "EKS Instance types"
  default     = ["m6a.xlarge"]
}

variable "eks_endpoint_public_access" {
  type        = bool
  description = "K8s Cluster Endpoint Public Access"
  default     = true
}

###################################
########### ALB Variables #########
###################################

# use load balancer private endpoint
variable "agic_internal" {
  type        = bool
  description = "Loadbalancer Internal or Public"
  default     = false
}

# allowed cidrs on lb
variable "allowed_lb_cidrs" {
  type        = list(string)
  description = "Allowed CIDRS"
  default     = ["0.0.0.0/0"]
}

###################################
####### Postgresql Variables ######
###################################
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
  description = "Postgresql admin password. null = generate."
  default     = null
  sensitive   = true
}

variable "pg_backup_retention" {
  type        = number
  description = "Posgresql Backup retention in days"
  default     = 7
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance type (e.g., db.t4g.xlarge)"
  default     = "db.m6g.xlarge"
}
variable "db_allocated_storage" {
  type        = number
  description = "Posgresql Disk Size"
  default     = 256
}

variable "db_max_allocated_storage" {
  type        = number
  description = "Posgresql Disk Size"
  default     = 512
}

variable "db_storage_type" {
  type        = string
  description = "EBS volume type for RDS storage. gp3 recommended over gp2 for better IOPS/throughput at lower cost."
  default     = "gp3"
}

variable "db_multi_az" {
  type        = bool
  description = "Enable Multi-AZ deployment for high availability"
  default     = false
}

variable "db_publicly_accessible" {
  type        = bool
  description = "Whether the DB instance is publicly accessible"
  default     = false
}

variable "db_deletion_protection" {
  type        = bool
  description = "Enable deletion protection for the DB instance"
  default     = false
}

variable "maintenance_window" {
  type        = string
  description = "Weekly maintenance window (UTC)"
  default     = "Mon:00:00-Mon:03:00"
}

variable "backup_window" {
  type        = string
  description = "Daily backup window (UTC)"
  default     = "03:00-06:00"
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot"
  default     = true
}

variable "delete_automated_backups" {
  type        = bool
  description = "Delete Automated backup"
  default     = true
}

###################################
########## Valkey Cache ###########
###################################
variable "use_managed_cache" {
  type        = bool
  description = "Azure Provided managed redis, if set false redis will be installed in aks cluster"
  default     = false
}

variable "valkey_port" {
  type        = number
  description = "Port on which Valkey (Redis-compatible) runs"
  default     = 6379
}

variable "valkey_engine" {
  type        = string
  description = "Cache engine type"
  default     = "valkey"
}

variable "valkey_engine_version" {
  type        = string
  description = "Version of Valkey engine"
  default     = "8.0"
}

variable "valkey_node_type" {
  type        = string
  description = "Instance type for cache nodes (e.g., cache.t4g.small)"
  default     = "cache.t4g.small"
}

variable "valkey_num_cache_nodes" {
  type        = number
  description = "Number of cache nodes in the cluster"
  default     = 1
}

variable "valkey_parameter_group_family" {
  type        = string
  description = "Parameter group family for Valkey"
  default     = "valkey8"
}

variable "valkey_auth_token" {
  type        = string
  description = "Authentication token for Valkey"
  default     = null
}

variable "valkey_multi_az_enabled" {
  type        = bool
  description = "Enable Multi-AZ with automatic failover for Valkey. Requires valkey_num_cache_nodes >= 2 and database subnets across >= 2 AZs."
  default     = false
}

#######################################
######## OpenSearch Variables #########
#######################################
variable "opensearch_engine_version" {
  type        = string
  description = "OpenSearch Engine Version"
  default     = "OpenSearch_3.5"
}

variable "opensearch_instance_type" {
  type        = string
  description = "OpenSearch Instance Size"
  default     = "r6g.large.search"
}

variable "opensearch_instance_count" {
  type        = number
  description = "OpenSearch Instance Count"
  default     = 1
}

variable "opensearch_admin_username" {
  type        = string
  description = "Elasticsearch Admin Username"
  default     = "elastic"
}

variable "opensearch_volume_size" {
  type        = number
  description = "Opensearch volume size"
  default     = 256
}

variable "opensearch_volume_type" {
  type        = string
  description = "Opensearch volume type"
  default     = "gp3"
}

variable "opensearch_tls_security_policy" {
  type        = string
  description = "Opensearch TLS Security Policy"
  default     = "Policy-Min-TLS-1-2-2019-07"
}

variable "opensearch_admin_password" {
  type        = string
  description = "OpenSearch master user password. AWS requires >=8 chars with lowercase, uppercase, digit, and special character."
  sensitive   = true
  default     = null

  validation {
    # null means "generate it", and the generator already satisfies the rule.
    condition = (
      var.opensearch_admin_password == null ||
      length(var.opensearch_admin_password) >= 8 &&
      can(regex("[a-z]", var.opensearch_admin_password)) &&
      can(regex("[A-Z]", var.opensearch_admin_password)) &&
      can(regex("[0-9]", var.opensearch_admin_password)) &&
      can(regex("[^A-Za-z0-9]", var.opensearch_admin_password))
    )
    error_message = "opensearch_admin_password must be at least 8 characters and include lowercase, uppercase, digit, and a special character."
  }
}

variable "opensearch_dedicated_master_enabled" {
  type        = bool
  description = "Elasticsearch Admin Password"
  default     = false
}

variable "opensearch_multi_az_enabled" {
  type        = bool
  description = "Enable multi-AZ (zone awareness) for OpenSearch. Requires 2 or 3 database subnets; opensearch_instance_count must be a multiple of the subnet count."
  default     = false
}

#######################################
######### Cassandra Variables #########
#######################################
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

variable "aws_cassandra_instance_type" {
  description = "AWS VM Type for Cassandra nodes. c6g.xlage = 4 vCPU / 8GB RAM."
  type        = string
  default     = "c6g.xlarge"
}

variable "aws_cassandra_vm_keypair" {
  type        = string
  description = "Public Key for Cassandra Node's Login"
  default     = ""
  validation {
    condition     = var.cassandra_node_count == 0 || length(var.aws_cassandra_vm_keypair) > 0
    error_message = "Its mandatory to provide the cassandra vm public key. Generate using:- ssh-keygen -t ed25519 -C '<Descriptive Name>' Then Copy the content from id_ed25519.pub and add in aws_cassandra_vm_keypair in terraform.tfvars"
  }
}

#######################################
######### Apps Variables ##############
#######################################

# services helm charts versions
variable "namespace" {
  type    = string
  default = "default"
}

variable "temporal_chart_version" {
  type        = string
  description = "Temporal Helm Chart Version"
  default     = "0.54.7"
}

variable "nected_chart_version" {
  type        = string
  description = "Nected Helm Chart Version"
  default     = "0.4.70"
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

# Nected app env configuration variables
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

variable "secret_manager" {
  description = <<-EOT
    Sync Nected's credentials from AWS Secrets Manager into a Kubernetes Secret
    via the secretsmanager subchart.

    Terraform creates <name_prefix>/app and pushes the generated credentials
    into it, creates an IAM role with read access, and binds it to the chart's
    service account with EKS Pod Identity.

    It does NOT create <name_prefix>/encryption-at-rest, and the chart never
    writes to the vault: that item is only a restore source. A generated key
    lives only in the Kubernetes Secret until you copy it out and store it
    there (or pass it as nected_common_secret_value).
  EOT

  type = object({
    enabled = optional(bool, false)

    # Item names are derived: <name_prefix>/app and
    # <name_prefix>/encryption-at-rest.
    name_prefix   = optional(string, "nected/prod")
    target_secret = optional(string, "nected-credential")

    required_keys = optional(list(string), [
      "DB_PASSWORD",
      "MASTER_DB_PASSWORD",
      "REDIS_PASSWORD",
      "ELASTIC_PASSWORD",
      "AES_SECRET",
      "JWT_SECRET",
      "NECTED_USER_PASSWORD",
    ])

    aliases = optional(map(string), {
      MASTER_DB_PASSWORD     = "DB_PASSWORD"
      VIDHAAN_REDIS_PASSWORD = "REDIS_PASSWORD"
    })
    fail_open = optional(bool, true)

    temporal_password_key = optional(string, "MASTER_DB_PASSWORD")
    service_account_name  = optional(string, "nected-secret-sync")

    # Customer-managed key for the secret, and how long a delete is recoverable.
    kms_key_arn             = optional(string, null)
    recovery_window_in_days = optional(number, 30)
  })

  default = {}
}

# ---------------------------------------------------------------------------
# Generated credentials
#
# Every variable below defaults to null, meaning "generate it". Supply one in
# tfvars to use your own value instead. Nothing ships a default password.
# ---------------------------------------------------------------------------

variable "datastore_password_version" {
  description = <<-EOT
    Bump to rotate the generated Postgres, OpenSearch and Valkey passwords.

    The engine and the vault must change together, so this also feeds
    db_password_version on the RDS instance. A rolling pod restart is not
    atomic, so expect a brief window where some pods hold the old password.
  EOT
  type        = number
  default     = 1
}

variable "app_password_version" {
  description = <<-EOT
    Bump to rotate the generated JWT secret, console password and default
    vidhaan secret key. Rotating the JWT secret logs every user out.

    AES_SECRET is deliberately NOT covered: changing it makes previously
    encrypted data unreadable.
  EOT
  type        = number
  default     = 1
}

variable "nected_jwt_secret" {
  description = "JWT signing secret. null = generate."
  type        = string
  default     = null
  sensitive   = true
}

variable "nected_aes_secret" {
  description = <<-EOT
    AES secret used to encrypt stored data. null = generate once.

    Treat as immutable: changing it makes anything encrypted under the old
    value unreadable. For an existing environment, pass the value already in
    use rather than letting a new one be generated.
  EOT
  type        = string
  default     = null
  sensitive   = true
}

variable "nected_email_password" {
  description = "SMTP password. null/empty = email disabled."
  type        = string
  default     = null
  sensitive   = true
}

variable "nected_ses_secret_key" {
  description = "AWS_SECRET_KEY for SES, when EMAIL_PROVIDER is ses."
  type        = string
  default     = null
  sensitive   = true
}

