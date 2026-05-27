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

variable "eks_oidc_provider_arn" {

}

variable "eks_oidc_provider_url" {

}