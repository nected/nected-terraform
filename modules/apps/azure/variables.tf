#######################################
# Subscription & Resource Information
#######################################

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name where resources are deployed"
}

variable "resource_group_location" {
  type        = string
  description = "Azure region for resource deployment"
}

variable "namespace" {
  type        = string
  description = "Namespace used for resource naming and deployment"
}

#######################################
# Managed Identity
#######################################

variable "identity_id" {
  type        = string
  description = "Resource ID of the user-assigned managed identity"
}

variable "identity_client_id" {
  type        = string
  description = "Client ID of the user-assigned managed identity"
}

variable "identity_principal_id" {
  type        = string
  description = "Principal ID of the user-assigned managed identity"
}

variable "aks_identity_principal_id" {
  type        = string
  description = "Principal ID of the AKS managed identity"
}

#######################################
# Key Vault & Secrets
#######################################

variable "key_vault_name" {
  type        = string
  description = "Name of the Azure Key Vault"
}

variable "cert_vault_name" {
  type        = string
  description = "Name of the Key Vault containing SSL certificates"
}

variable "cert_secret_name" {
  type        = string
  description = "Name of the Key Vault secret containing the SSL certificate"
}

variable "alb_vault_secret_endpoint" {
  type        = string
  description = "Key Vault secret endpoint used by the Application Load Balancer"
}

#######################################
# Networking
#######################################

variable "appgw_subnet_id" {
  type        = string
  description = "Subnet ID for the Application Gateway"
}

variable "internal_app_gateway_ip" {
  type        = string
  description = "Private IP address of the Application Gateway"
}

variable "public_app_gateway_ip" {
  type        = string
  description = "Public IP address of the Application Gateway"
}

variable "public_app_gateway_id" {
  type        = string
  description = "Resource ID of the public Application Gateway"
}

#######################################
# DNS & Domains
#######################################

variable "az_hosted_zone" {
  type        = string
  description = "Azure DNS hosted zone name"
}

variable "hosted_zone_rg" {
  type        = string
  description = "Resource group containing the DNS hosted zone"
}

variable "base_domain" {
  type        = string
  description = "Base domain name"
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

#######################################
# Application Gateway Certificates
#######################################

variable "agic_ssl_certificate_identifer" {
  type        = string
  description = "SSL certificate identifier used by AGIC/Application Gateway"
}

#######################################
# Application Configuration
#######################################

variable "console_user_email" {
  type        = string
  description = "Email address for the console user account"
}