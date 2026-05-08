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

variable "project" {
  type = string
  description = "Project Name"
}

variable "environment" {
  type = string
  description = "Environment Name"
}