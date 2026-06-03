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
  type = string
  description = "AWS Region"

}