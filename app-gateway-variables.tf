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

# SSL Certificate Configuration
variable "ssl_certificate_path" {
  type        = string
  description = "Path to SSL certificate PFX file"
  default     = ""
}

variable "ssl_certificate_data" {
  type        = string
  description = "Base64 encoded SSL certificate data (alternative to file path)"
  default     = ""
  sensitive   = true
}

variable "ssl_certificate_password" {
  type        = string
  description = "Password for SSL certificate"
  default     = ""
  sensitive   = true
}

variable "ssl_certificate_name" {
  type        = string
  description = "Name of the SSL certificate in Key Vault"
  default     = ""
}

variable "backend_ssl_cert_path" {
  type        = string
  description = "Path to backend SSL certificate for end-to-end encryption"
  default     = ""
}

variable "key_vault_id" {
  type        = string
  description = "ID of Key Vault containing SSL certificates"
  default     = ""
}

# Backend Pool Configuration
variable "aks_service_fqdns" {
  type        = list(string)
  description = "List of FQDNs for AKS services"
  default     = []
}

variable "additional_backend_pools" {
  type = list(object({
    name         = string
    fqdns        = optional(list(string))
    ip_addresses = optional(list(string))
  }))
  description = "Additional backend address pools"
  default     = []
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

# Hostname Configuration
variable "additional_hostnames" {
  type        = list(string)
  description = "Additional hostnames for SNI-based routing"
  default     = []
}

# Path-based Routing
variable "enable_path_based_routing" {
  type        = bool
  description = "Enable path-based routing"
  default     = false
}

variable "path_rules" {
  type = list(object({
    name                  = string
    paths                 = list(string)
    backend_pool_name     = string
    backend_settings_name = string
  }))
  description = "Path-based routing rules"
  default     = []
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
  default     = "Prevention"
}

variable "waf_rule_set_version" {
  type        = string
  description = "WAF rule set version"
  default     = "3.2"
}

# Application Gateway Subnet CIDR
variable "appgw_subnet_cidr" {
  type        = string
  description = "CIDR block for Application Gateway subnet"
  default     = ""
}

variable "agic_internal" {
  type        = bool
  description = "Application gateway Internal or Public"
  default     = false
}