module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = "${var.project}-${var.environment}"
  cidr = var.vpc_cidr

  azs             = var.azs
  public_subnets  = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, var.subnet_newbits, k)]
  private_subnets = [for k, v in var.azs : cidrsubnet(var.vpc_cidr, var.subnet_newbits, k + length(var.azs))]

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  tags = merge(var.tags, {
    Environment = var.environment
    Name        = "${var.project}-${var.environment}"
  })
}

# module "eks_cluster" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 21.17"

#   name               = "${var.project}-${var.environment}"
#   kubernetes_version = var.kubernetes_version

#   # EKS Addons
#   addons = {
#     coredns = {}
#     eks-pod-identity-agent = {
#       before_compute = true
#     }
#     kube-proxy = {}
#     vpc-cni = {
#       before_compute = true
#     }
#   }

#   endpoint_private_access = true
#   endpoint_public_access  = false

#   enable_cluster_creator_admin_permissions = true

#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.private_subnets

#   # Default it will be public

#   tags = merge(var.tags, {
#     Environment = var.environment
#     Name        = "${var.project}-${var.environment}"
#   })

#   eks_managed_node_groups = {
#     default = {
#       name           = "${var.project}-${var.environment}-default"
#       min_size       = 1
#       max_size       = 3
#       desired_size   = 1
#       instance_types = var.node_instance_types

#       labels = {
#         nodegroup = "default"
#         cluster   = "${var.project}-${var.environment}"
#       }
#     }
#   }
# }