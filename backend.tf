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

# ----- AWS S3 backend (cloud_provider = "aws") -----
# terraform {
#   backend "s3" {
#     bucket       = "<TFSTATE_BUCKET>"
#     key          = "nected/terraform.tfstate"
#     region       = "ap-south-1"
#     profile      = "aws-dev"
#     encrypt      = true
#     use_lockfile = true              # Terraform >= 1.10 native S3 locking
#     # dynamodb_table = "<LOCK_TABLE>" # alternative for Terraform < 1.10
#   }
# }
