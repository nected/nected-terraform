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

  depends_on = [module.vpc, aws_security_group.alb]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS listener — default action returns 404
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.aws_certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# One target group + listener rule per service
locals {
  services = {
    ui = {
      domain      = var.ui_domain
      port        = 80
      health_path = "/"
    }
    backend = {
      domain      = var.backend_domain
      port        = 80
      health_path = "/"
    }
    router = {
      domain      = var.router_domain
      port        = 80
      health_path = "/"
    }
  }
}

resource "aws_lb_target_group" "this" {
  for_each = local.services

  name        = "${var.project}-${each.key}-${var.environment}"
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    path                = each.value.health_path
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
  }
}

resource "aws_lb_listener_rule" "this" {
  for_each = local.services

  listener_arn = aws_lb_listener.https.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  condition {
    host_header {
      values = [each.value.domain]
    }
  }
}