# cassandra.tf 
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical official account

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

# locals
locals {
  cassandra_node_count = var.cassandra_node_count
  seed_count           = local.cassandra_node_count == 7 ? 3 : 2

  cassandra_nodes = {
    for i in range(local.cassandra_node_count) :
    "cassandra-${i + 1}" => {
      index      = i
      subnet_idx = i % length(local.private_subnets)
      tags       = i < local.seed_count ? { Seed : true } : { Seed : false }
    }
  }
  cassandra_user_data = join("\n", [
    "#!/bin/bash",
    "export CLUSTER_NAME=\"${var.project}-${var.environment}-cluster\"",
    "export ENVIRONMENT=\"${var.environment}\"",
    "export SERVICE=\"cassandra\"",
    "export PROJECT=\"${var.project}\"",
    file("${path.module}/install-cassandra.sh"),
  ])
}

# Cassadnra Keypair
resource "aws_key_pair" "deployer" {
  count      = local.cassandra_node_count > 0 ? 1 : 0
  key_name   = "${var.project}-${var.environment}"
  public_key = var.aws_cassandra_vm_keypair
}

# Cassandra Security Group
resource "aws_security_group" "cassandra" {
  count       = local.cassandra_node_count > 0 ? 1 : 0
  name        = "${var.project}-cassandra-sg-${var.environment}"
  description = "Cassandra SG"
  vpc_id      = local.vpc_id

  ingress {
    from_port = 7000
    to_port   = 7000
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port   = 9042
    to_port     = 9042
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role
resource "aws_iam_role" "cassandra" {
  count = local.cassandra_node_count > 0 ? 1 : 0
  name  = "${var.project}-cass-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project}-cass-${var.environment}"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_policy" "cassandra_seed_discovery" {
  count       = local.cassandra_node_count > 0 ? 1 : 0
  name        = "${var.project}-cass-${var.environment}"
  description = "Allows Cassandra nodes to discover peers via EC2 tags"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2SeedDiscovery"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances"
        ]
        Resource = "*"
        # Scope down to the same account/region via a condition
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cassandra_seed_discovery" {
  count      = local.cassandra_node_count > 0 ? 1 : 0
  role       = aws_iam_role.cassandra[0].name
  policy_arn = aws_iam_policy.cassandra_seed_discovery[0].arn
}

resource "aws_iam_instance_profile" "cassandra" {
  count = local.cassandra_node_count > 0 ? 1 : 0
  name  = "${var.project}-cass-${var.environment}"
  role  = aws_iam_role.cassandra[0].name

  tags = {
    Name        = "${var.project}-cass-${var.environment}"
    Environment = var.environment
    Project     = var.project
  }
}

# Cassandra Instance
resource "aws_instance" "cassandra" {
  for_each = local.cassandra_nodes

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.cassandra_instance_type
  subnet_id     = element(local.private_subnets, each.value.index % length(local.private_subnets))

  vpc_security_group_ids = [aws_security_group.cassandra[0].id]
  iam_instance_profile   = aws_iam_instance_profile.cassandra[0].name
  key_name               = aws_key_pair.deployer[0].key_name

  root_block_device {
    volume_size = var.cassandra_root_disk_size_gb
    volume_type = var.cassandra_root_disk_type
    encrypted   = true
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = var.cassandra_data_disk_size_gb
    volume_type = var.cassandra_data_disk_type
    encrypted   = true
  }

  user_data_base64 = base64encode(local.cassandra_user_data)

  tags = merge(each.value.tags, {
    Name        = "${var.project}-${var.environment}-${each.key}"
    Environment = var.environment
    Service     = "cassandra"
    Project     = var.project
    Ownedby     = "nected"
  })
}