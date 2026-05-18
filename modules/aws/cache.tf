resource "aws_security_group" "valkey" {
  count = var.use_managed_redis ? 1 : 0

  name   = "${var.project}-valkey-sg-${var.environment}"
  vpc_id = local.vpc_id

  ingress {
    description = "Valkey from ${var.project} App"
    from_port   = var.valkey_port
    to_port     = var.valkey_port
    protocol    = "tcp"

    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "valkey" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.11"

  count = var.use_managed_redis ? 1 : 0

  replication_group_id = "${var.project}-cache-${var.environment}"
  engine               = var.valkey_engine
  engine_version       = var.valkey_engine_version
  node_type            = var.valkey_node_type
  num_cache_nodes      = var.valkey_num_cache_nodes
  port                 = var.valkey_port

  subnet_ids = local.database_subnets

  subnet_group_name = "${var.project}-subnet-grp-${var.environment}"

  create_security_group = "false"

  security_group_ids = [aws_security_group.valkey[0].id]

  parameter_group_family = var.valkey_parameter_group_family

  transit_encryption_enabled = true

  at_rest_encryption_enabled = true

  auth_token = var.valkey_auth_token

  apply_immediately = true

  tags = merge(var.tags, {
    Environment = var.environment
    Name        = "${var.project}-cache-${var.environment}"
  })
}