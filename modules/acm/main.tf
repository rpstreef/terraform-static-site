#
# ACM Certificate
#
resource "aws_acm_certificate" "_" {
  domain_name               = var.domain_name
  validation_method         = "DNS"
  subject_alternative_names = [var.domain_name, "*.${var.domain_name}"]

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate._.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate._.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}

