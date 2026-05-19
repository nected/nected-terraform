variable "project" {
  description = "Project name"
  type        = string
  default     = "nected"
}

variable "environment" {
  description = "Environment (dev, prod)"
  type        = string
  default     = "prod"
}

# -------------------
# VPC Variables
# -------------------
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
  description = "Existing Public Private Subnets"
  default     = []
}


variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
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

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway"
  type        = bool
  default     = true
}

# -------------------
# Kubernetes & Node Group Variables
# -------------------

variable "kubernetes_version" {
  description = "Kubernetes Version"
  type        = string
  default     = "1.35"
}

variable "node_instance_types" {
  description = "Instance type for node group"
  type        = list(string)
  default     = ["m6a.xlarge"]
}

variable "node_min_count" {
  description = "Minimum nodes"
  type        = number
  default     = 2
}

variable "node_max_count" {
  description = "Maximum nodes"
  type        = number
  default     = 5
}

variable "node_desired_count" {
  description = "Desired nodes"
  type        = number
  default     = 2
}

variable "endpoint_private_access" {
  type        = bool
  description = "Cluster Endpoint Private Access"
  default     = true
}

variable "endpoint_public_access" {
  type        = bool
  description = "K8s Cluster Endpoint Public Access"
  default     = true
}

variable "enable_cluster_creator_admin_permissions" {
  type        = bool
  description = "Enable Cluster Creator Admin"
  default     = true
}
# -------------------
# Tags
# -------------------

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Terraform = "true"
  }
}

# --------------------
# DB Parameters
# ----------------

variable "db_engine" {
  type        = string
  description = "Database engine type"
  default     = "postgres"
}

variable "db_engine_version" {
  type        = string
  description = "Version of the database engine"
  default     = "17"
}

variable "db_family" {
  type        = string
  description = "Database parameter group family"
  default     = "postgres17"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance type (e.g., db.m7i.xlarge)"
  default     = "db.m7i.xlarge"
}

variable "db_allocated_storage" {
  type        = number
  description = "Initial storage allocated to the database (in GB)"
  default     = 50
}

variable "db_max_allocated_storage" {
  type        = number
  description = "Maximum storage autoscaling limit (in GB)"
  default     = 200
}

variable "db_port" {
  description = "Database Port Number"
  type        = number
  default     = 5432
}

variable "db_name" {
  type        = string
  description = "Name of the initial database"
  default     = "nected"
}

variable "db_username" {
  type        = string
  description = "Master username for the database"
  default     = "postgres"
}

variable "db_password" {
  description = "The database password"
  type        = string
  default     = "FZv6r6s13LHLZeNj8TpMcxjH"
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

variable "backup_retention_period" {
  type        = number
  description = "Number of days to retain backups"
  default     = 7
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


#------------------
# Cache - Valkey
#------------------
variable "use_managed_redis" {
  type        = bool
  description = "Use managed Cache(Valkey)"
  default     = true
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
  default     = "YyJgOWW6VSKLwJQUmlvebArysMrm02NYM2au7o"
}

#----------------------------
# OpenSearch
#----------------------------
variable "opensearch_engine_version" {
  type        = string
  description = "OpenSearch Engine Version"
  default     = "OpenSearch_2.11"
}

variable "opensearch_instance_type" {
  type        = string
  description = "OpenSearch Instance Size"
  default     = "t3.medium.search"
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
  default     = 50
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
  description = "Elasticsearch Admin Password"
}

# ---------------------
# Cassandra 
# ----------------

variable "cassandra_node_count" {
  type        = number
  description = "Cassandra Node Count"
  default     = 3
}

variable "cassandra_instance_type" {
  type        = string
  description = "Cassandra Node Instance Type"
  default     = "t3.small"
}

variable "key_name" {
  type        = string
  description = "Cassandra Node SSH Keyname"
  default     = "dev-nected"
}