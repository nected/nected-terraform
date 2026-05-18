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

variable "single_nat_gateway" {
  description = "Use single NAT Gateway"
  type        = bool
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
  description = "Instance type for cache nodes (e.g., cache.t3.micro)"
  default     = "cache.t4g.small"
}

variable "valkey_num_cache_nodes" {
  type        = number
  description = "Number of cache nodes in the cluster"
  default     = 1
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
  default     = 20
}

variable "db_max_allocated_storage" {
  type        = number
  description = "Posgresql Disk Size"
  default     = 200
}

# EKS
variable "eks_node_instance_types" {
  type        = list(string)
  description = "EKS Instance types"
  default     = ["m6a.xlarge"]
}