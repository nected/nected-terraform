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

# VNet Variables
variable "vnet_address_space" {
  type        = string
  description = "The address space of the VNet"
  default     = "10.50.0.0/16"
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
  default     = 65536
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

# App resources & autoscaling
variable "temporal_task_partitions" {
  type        = number
  description = "Temporal tasks partitions"
  default     = 20
}
variable "temporal_service_autoscale" {
  type        = bool
  description = "Temporal Service Autoscale"
  default     = false
}

variable "temporal_chart_version" {
  type        = string
  description = "Temporal Helm Chart Version"
  default     = "0.54.0"
}

variable "nected_service_autoscale" {
  type        = bool
  description = "Nected Service Autoscale"
  default     = false
}

variable "nected_chart_version" {
  type        = string
  description = "Nected Helm Chart Version"
  default     = "0.4.10"
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

# DNS hosted Zone
variable "hosted_zone" {
  type        = string
  description = "Enter hosted zone"
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "nected_pre_shared_key" {
  type    = string
  default = "1182d659-8c9b-4541-90ac-8546372c326f"
}