# resource "aws_security_group" "valkey" {
#   name   = "${var.project}-valkey-sg-${var.environment}"
#   vpc_id = module.vpc.vpc_id

#   ingress {
#     description = "Valkey from ${var.project} App"
#     from_port   = var.valkey_port
#     to_port     = var.valkey_port
#     protocol    = "tcp"

#     cidr_blocks = [var.vpc_cidr]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# module "valkey" {
#   source  = "terraform-aws-modules/elasticache/aws"
#   version = "~> 1.11"

#   replication_group_id = "${var.project}-cache-${var.environment}"
#   engine               = var.valkey_engine
#   engine_version       = var.valkey_engine_version
#   node_type            = var.valkey_node_type
#   num_cache_nodes      = var.valkey_num_cache_nodes
#   port                 = var.valkey_port

#   subnet_ids = module.vpc.private_subnets

#   subnet_group_name = "${var.project}-subnet-grp-${var.environment}"

#   create_security_group = "false"

#   security_group_ids = [aws_security_group.valkey.id]

#   parameter_group_family = var.valkey_parameter_group_family

#   apply_immediately = true

#   tags = merge(var.tags, {
#     Environment = var.environment
#     Name        = "${var.project}-cache-${var.environment}"
#   })
# }