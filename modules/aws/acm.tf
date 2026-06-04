
# Request the ACM Certificate
resource "aws_acm_certificate" "cert" {
  count = var.route53_hosted_zone && var.aws_certificate_arn == "" ? 1 : 0

  domain_name       = var.hosted_zone_domain
  validation_method = "DNS"

  subject_alternative_names = [
    var.ui_domain,
    var.backend_domain,
    var.router_domain
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Environment = var.environment
  }
}

# Dynamic Record Creation in Route 53 for Certificate Validation
resource "aws_route53_record" "cert_validation" {
    for_each = var.route53_hosted_zone && var.aws_certificate_arn == "" ? {
        for dvo in aws_acm_certificate.cert[0].domain_validation_options : dvo.domain_name => {
            name   = dvo.resource_record_name
            record = dvo.resource_record_value
            type   = dvo.resource_record_type
        }
    } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.primary[0].zone_id
}

# Complete the validation handshake
resource "aws_acm_certificate_validation" "cert" {
  count = var.route53_hosted_zone && var.aws_certificate_arn == "" ? 1 : 0
  
  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}