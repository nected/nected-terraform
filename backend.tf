# terraform {
#   backend "azurerm" {
#     resource_group_name  = "<RESOURCE_GROUP>"
#     storage_account_name = "<STORAGE_ACCOUNT_NAME>"
#     container_name       = "<CONTAINER_NAME>"
#     key                  = "<TFSTATE_FILE_NAME>.tfstate"
#   }
# }

terraform {
  backend "azurerm" {
    resource_group_name  = "nected-dev"
    storage_account_name = "tfstate10gpx"
    container_name       = "tfstate"
    key                  = "nected.terraform.tfstate"
  }
}
