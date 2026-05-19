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

# Network

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
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = []

  validation {
    condition     = var.cloud_provider != "aws" || length(var.azs) > 0
    error_message = "provide at least one availability zone in var.azs when cloud_provider is \"aws\""
  }

  validation {
    condition     = var.cloud_provider != "aws" || alltrue([for az in var.azs : startswith(az, var.aws_region)])
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

# EKS
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

# SSL certificate ARN
variable "aws_certificate_arn" {
  type        = string
  description = "AWS Certificate Manager - Cert ARN"
  default     = ""

  validation {
    condition     = var.cloud_provider != "aws" || length(trimspace(var.aws_certificate_arn)) > 0
    error_message = "aws_certificate_arn must not be empty when cloud_provider is \"aws\"."
  }
}

# Postgresql
variable "db_instance_class" {
  type        = string
  description = "RDS instance type (e.g., db.t4g.xlarge)"
  default     = "db.t4g.xlarge"
}
variable "db_allocated_storage" {
  type        = number
  description = "Posgresql Disk Size"
  default     = 50
}

variable "db_max_allocated_storage" {
  type        = number
  description = "Posgresql Disk Size"
  default     = 200
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

# Valkey Cache
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

# OpenSearch
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
  default     = "jeuusbhweh458sgggHGrjfk"
}
