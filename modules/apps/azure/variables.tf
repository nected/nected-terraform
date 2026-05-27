variable "key_vault_name" {

}

variable "resource_group_name" {

}

variable "resource_group_location" {

}

variable "appgw_subnet_id" {
}

variable "internal_app_gateway_ip" {

}

variable "az_hosted_zone" {

}
variable "console_user_email" {
  type        = string
  description = "Email address for the console user account"
}


variable "hosted_zone_rg" {

}

variable "namespace" {

}
variable "base_domain" {
  type        = string
  description = "base domain"
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

variable "cert_vault_name" {

}

variable "cert_secret_name" {

}

variable "subscription_id" {

}

variable "identity_id" {}
variable "identity_client_id" {}
variable "alb_vault_secret_endpoint" {

}

variable "public_app_gateway_ip" {

}
variable "public_app_gateway_id" {

}

variable "aks_identity_principal_id" {

}

variable "identity_principal_id" {

}

variable "agic_ssl_certificate_identifer" {

}