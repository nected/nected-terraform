resource "aws_security_group" "rds" {
  name        = "${var.project}-psql-sg-${var.environment}"
  description = "Allow PostgreSQL access"
  vpc_id      = local.vpc_id

  ingress {
    description = "PostgreSQL from ${var.project} App"
    from_port   = var.db_port
    to_port     = var.db_port
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
    Name        = "${var.project}-psql-sg-${var.environment}"
  })

  depends_on = [module.vpc]
}

module "postgres" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 7.2"

  identifier = "${var.project}-psql-${var.environment}"

  engine         = var.db_engine
  engine_version = var.db_engine_version
  family         = var.db_family

  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = var.db_storage_type

  manage_master_user_password = false

  db_name             = var.db_name
  username            = var.db_username
  password_wo         = var.db_password
  password_wo_version = 1
  port                = var.db_port

  multi_az            = var.db_multi_az
  publicly_accessible = var.db_publicly_accessible
  deletion_protection = var.db_deletion_protection

  vpc_security_group_ids = [aws_security_group.rds.id]
  create_db_subnet_group = "true"
  db_subnet_group_name   = "${var.project}-subnet-grp-${var.environment}"
  subnet_ids             = local.database_subnets

  maintenance_window = var.maintenance_window
  backup_window      = var.backup_window

  backup_retention_period  = var.backup_retention_period
  skip_final_snapshot      = var.skip_final_snapshot
  delete_automated_backups = var.delete_automated_backups

  final_snapshot_identifier_prefix = var.skip_final_snapshot ? null : "${var.project}-final-${var.environment}"


  tags = merge(var.tags, {
    Environment = var.environment
    Name        = "${var.project}-psql-${var.environment}"
  })

  depends_on = [module.vpc, aws_security_group.rds]
}