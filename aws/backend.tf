# ----- AWS S3 backend -----
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

terraform {
  backend "s3" {
    bucket       = "nected-tfstate"
    key          = "nected/terraform.tfstate"
    region       = "ap-south-1"
    profile      = "aws-dev"
    encrypt      = true
    use_lockfile = true
  }
}