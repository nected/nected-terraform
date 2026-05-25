resource "aws_lb" "this" {
  name               = "${var.project}-${var.environment}"
  internal           = var.agic_internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.agic_internal ? local.private_subnets : local.public_subnets

  tags = {
    Name                       = "${var.project}-lb-${var.environment}"
    Environment                = var.environment
    "elbv2.k8s.aws/cluster"    = "${var.project}-${var.environment}"
    "ingress.k8s.aws/stack"    = "${var.project}-alb-${var.environment}"
    "ingress.k8s.aws/resource" = "LoadBalancer"
  }
}