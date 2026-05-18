# # cassandra.tf 
# data "aws_ami" "ubuntu" {
#   most_recent = true
#   owners      = ["099720109477"] # Canonical official account

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

# # locals
# locals {
#   cassandra_node_count = var.cassandra_node_count
#   cassandra_base_offset = 100

#   cassandra_nodes = {
#     for i in range(local.cassandra_node_count) :
#     "cassandra-${i + 1}" => {
#       index = i
#       subnet_idx = i % length(module.vpc.private_subnets)

#       # deterministic IP per subnet
#       private_ip = cidrhost(
#         module.vpc.private_subnets_cidr_blocks[i % length(module.vpc.private_subnets)],
#         local.cassandra_base_offset + floor(i / length(module.vpc.private_subnets))
#       )
#     }
#   }

#   seed_nodes = [
#     for k, v in local.cassandra_nodes :
#     v.private_ip if v.index < length(module.vpc.private_subnets)
#   ]
#   seed_nodes_joined = join(",", local.seed_nodes)
# }

# resource "aws_security_group" "cassandra" {
#   name        = "${var.project}-cassandra-sg-${var.environment}"
#   description = "Cassandra SG"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port = 7000
#     to_port   = 7000
#     protocol  = "tcp"
#     self      = true
#   }

#   ingress {
#     from_port   = 9042
#     to_port     = 9042
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

# resource "aws_instance" "cassandra" {
#   for_each = local.cassandra_nodes

#   ami           = data.aws_ami.ubuntu.id
#   instance_type = var.cassandra_instance_type
#   subnet_id     = element(module.vpc.private_subnets, each.value.index % length(module.vpc.private_subnets))

#   vpc_security_group_ids = [aws_security_group.cassandra.id]

#   key_name = var.key_name

#   user_data_base64 = base64encode(templatefile("${path.module}/install-cassandra.sh", {
#     seeds        = local.seed_nodes_joined
#     node_index   = each.value.index
#     cluster_name = "${var.project}-prod-cluster"
#   }))

#   tags = {
#     Name        = "${var.project}-${each.key}"
#     environment = var.environment
#     service     = "cassandra"
#   }
# }