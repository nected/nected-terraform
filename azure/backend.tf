# Remote state backend.
# Uncomment ONE of the blocks below based on cloud_provider in terraform.tfvars.
# Only one terraform { backend "..." } block can be active at a time.

# ----- Azure Blob backend (cloud_provider = "azure") -----
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "<RESOURCE_GROUP>"
#     storage_account_name = "<STORAGE_ACCOUNT_NAME>"
#     container_name       = "<CONTAINER_NAME>"
#     key                  = "<TFSTATE_FILE_NAME>.tfstate"
#   }
# }