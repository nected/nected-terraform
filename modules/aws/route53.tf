
# Create the Route 53 Alias Record pointing to the ALB for UI
resource "aws_route53_record" "ui" {
  count = var.route53_hosted_zone ? 1 : 0

  zone_id = data.aws_route53_zone.primary[0].zone_id
  name    = var.ui_domain
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

# Create the Route 53 Alias Record pointing to the ALB for backend
resource "aws_route53_record" "backend" {
  count = var.route53_hosted_zone ? 1 : 0

  zone_id = data.aws_route53_zone.primary[0].zone_id
  name    = var.backend_domain
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

# Create the Route 53 Alias Record pointing to the ALB for router
resource "aws_route53_record" "router" {
  count = var.route53_hosted_zone ? 1 : 0

  zone_id = data.aws_route53_zone.primary[0].zone_id
  name    = var.router_domain
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}