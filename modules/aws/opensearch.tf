resource "terraform_data" "opensearch_multi_az_validation" {
  lifecycle {
    precondition {
      condition     = !var.opensearch_multi_az_enabled || contains([2, 3], length(local.database_subnets))
      error_message = "opensearch_multi_az_enabled requires 2 or 3 database subnets (got ${length(local.database_subnets)}). For a new VPC set var.azs to 2 or 3 entries; for an existing VPC provide 2 or 3 entries in var.existing_database_subnets."
    }

    precondition {
      condition     = !var.opensearch_multi_az_enabled || var.opensearch_instance_count % length(local.database_subnets) == 0
      error_message = "opensearch_instance_count (${var.opensearch_instance_count}) must be a multiple of the database subnet count (${length(local.database_subnets)}) when opensearch_multi_az_enabled is true."
    }
  }
}

resource "aws_security_group" "opensearch" {
  name        = "${var.project}-search-sg-${var.environment}"
  description = "Allow Openseach access"
  vpc_id      = local.vpc_id

  ingress {
    description = "OpenSearch from ${var.project} App"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Environment = var.environment
    Name        = "${var.project}-search-sg-${var.environment}"
  })
}

module "opensearch" {
  source  = "terraform-aws-modules/opensearch/aws"
  version = "2.9.0"

  domain_name    = "${var.project}-opensearch-${var.environment}"
  engine_version = var.opensearch_engine_version

  advanced_security_options = {
    enabled                        = true
    internal_user_database_enabled = true

    master_user_options = {
      master_user_name     = var.opensearch_admin_username
      master_user_password = var.opensearch_admin_password
    }
  }

  cluster_config = {
    instance_type            = var.opensearch_instance_type
    instance_count           = var.opensearch_instance_count
    zone_awareness_enabled   = var.opensearch_multi_az_enabled
    dedicated_master_enabled = var.opensearch_dedicated_master_enabled

    zone_awareness_config = var.opensearch_multi_az_enabled ? {
      availability_zone_count = length(local.opensearch_subnets)
    } : null
  }

  ebs_options = {
    ebs_enabled = true
    volume_size = var.opensearch_volume_size
    volume_type = var.opensearch_volume_type
  }

  auto_tune_options = {
    desired_state = "DISABLED"
  }

  encrypt_at_rest = {
    enabled = true
  }

  node_to_node_encryption = {
    enabled = true
  }

  domain_endpoint_options = {
    enforce_https       = true
    tls_security_policy = var.opensearch_tls_security_policy
  }

  vpc_options = {
    subnet_ids = local.opensearch_subnets

    security_group_ids = [aws_security_group.opensearch.id]
  }

  access_policies = data.aws_iam_policy_document.opensearch.json

  tags = merge(var.tags, {
    Environment = var.environment
    Name        = "${var.project}-search-sg-${var.environment}"
  })
}