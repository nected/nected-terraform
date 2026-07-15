module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  count = var.existing_vpc_id == "null" ? 1 : 0

  name = "${var.project}-${var.environment}"
  cidr = var.vpc_cidr[0]

  azs              = var.azs
  public_subnets   = [for k, v in var.azs : cidrsubnet(var.vpc_cidr[0], var.subnet_newbits["public"], k + length(var.azs))]
  private_subnets  = [for k, v in var.azs : cidrsubnet(var.vpc_cidr[0], var.subnet_newbits["private"], k + length(var.azs))]
  database_subnets = [for k, v in var.azs : cidrsubnet(var.vpc_cidr[0], var.subnet_newbits["db"], k + length(var.azs))]

  public_subnet_suffix   = "public"
  private_subnet_suffix  = "private"
  database_subnet_suffix = "database"

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

resource "aws_security_group" "alb" {
  name   = "${var.project}-alb-${var.environment}"
  vpc_id = local.vpc_id

  ingress {
    description = "Allow HTTP Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    cidr_blocks = var.allowed_lb_cidrs
  }

  ingress {
    description = "Allow HTTPS Traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

    cidr_blocks = var.allowed_lb_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [module.vpc]
}

module "eks_cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.17"

  name               = "${var.project}-${var.environment}"
  kubernetes_version = var.kubernetes_version

  # Control plane logging -> CloudWatch (/aws/eks/<cluster>/cluster)
  enabled_log_types                      = var.eks_control_plane_log_types
  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = var.eks_log_retention_days

  # EKS Addons
  addons = merge(
    {
      coredns = {}
      eks-pod-identity-agent = {
        before_compute = true
      }
      kube-proxy = {}
      vpc-cni = {
        before_compute = true
      }
    },
    var.enable_cloudwatch_logging ? {
      # Managed CloudWatch agent + Fluent Bit (Container Insights + application logs)
      amazon-cloudwatch-observability = {
        pod_identity_association = [{
          role_arn        = aws_iam_role.cw_observability[0].arn
          service_account = "cloudwatch-agent"
        }]
      }
    } : {}
  )

  endpoint_private_access      = var.endpoint_private_access
  endpoint_public_access       = var.endpoint_public_access
  endpoint_public_access_cidrs = var.allowed_eks_cidrs


  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnets

  # Default it will be public

  tags = merge(var.tags, {
    Environment = var.environment
    Name        = "${var.project}-${var.environment}"
  })

  security_group_additional_rules = {
    ingress_443 = {
      description = "Access cluster API from External"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = var.allowed_eks_cidrs
    }
  }

  node_security_group_additional_rules = {
    nalanda_ingress_8001 = {
      description              = "Allow Nalanda traffic from ALB"
      protocol                 = "TCP"
      from_port                = 8001
      to_port                  = 8001
      type                     = "ingress"
      source_security_group_id = aws_security_group.alb.id
    }
    vidhan_ingress_8002 = {
      description              = "Allow Vidhan traffic from ALB"
      protocol                 = "TCP"
      from_port                = 8002
      to_port                  = 8002
      type                     = "ingress"
      source_security_group_id = aws_security_group.alb.id
    }
    konark_ingress_8080 = {
      description              = "Allow konark traffic from ALB"
      protocol                 = "TCP"
      from_port                = 8080
      to_port                  = 8080
      type                     = "ingress"
      source_security_group_id = aws_security_group.alb.id
    }
  }
  eks_managed_node_groups = {
    default = {
      name           = "${var.project}-${var.environment}-default"
      min_size       = var.node_min_count
      max_size       = var.node_max_count
      desired_size   = var.node_desired_count
      instance_types = var.node_instance_types

      labels = {
        nodegroup = "default"
        cluster   = "${var.project}-${var.environment}"
      }
    }
  }
}