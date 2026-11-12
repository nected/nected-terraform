terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Pinned to 4.x: azurerm 5 removed azurerm_subnet.service_endpoints and
      # dropped Grafana 11, both used here. ">= 4.0" silently resolved to 5.12
      # and broke validate. Moving to 5.x is its own migration.
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}
