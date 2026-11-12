variable "eks_cluster_name" {
  type        = string
  description = "eks cluster name"
}

variable "vpc_id" {
  type        = string
  description = "vpc id"
}

variable "environment" {
  type        = string
  description = "Environment to deploy"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"

}
variable "secret_manager" {
  description = <<-EOT
    Identity for the nected-secret-sync job. When enabled, creates an IAM role
    with READ-ONLY access to the given Secrets Manager items and binds it to
    (namespace, service_account_name) via EKS Pod Identity.
  EOT

  type = object({
    enabled              = optional(bool, false)
    namespace            = optional(string, "default")
    service_account_name = optional(string, "nected-secret-sync")
    # Read-only. The job never writes to Secrets Manager at all: it reads the
    # credentials items and, if configured, the encryption-at-rest item.
    secret_arns = optional(list(string), [])
    # Required only when the secrets use a customer-managed KMS key.
    kms_key_arn = optional(string, null)
  })

  default = {}

  validation {
    condition     = var.secret_manager.enabled == false || length(var.secret_manager.secret_arns) > 0
    error_message = "secret_manager.secret_arns must list at least one ARN when secret_manager.enabled is true."
  }
}
