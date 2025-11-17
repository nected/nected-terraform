# terraform {
#   backend "azurerm" {}
# }

# # Conditional Backend Configuration
# # 
# # Usage:
# # For REMOTE state: terraform init (default)
# # For LOCAL state: terraform init -backend=false
# #
# # For switching:
# # Remote to Local: terraform init -backend=false -migrate-state
# # Local to Remote: terraform init -migrate-state
