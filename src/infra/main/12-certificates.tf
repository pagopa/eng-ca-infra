data "external" "get_ns_primary" {
  program = ["bash", "./get_ns.sh", "${var.app_primary_domain_name}"]
}

resource "aws_acm_certificate" "api_validation" {
  domain_name               = "${var.app_api_subdomain_name}.${var.app_primary_domain_name}"
  subject_alternative_names = ["${var.app_api_subdomain_name}.${var.app_primary_domain_name}"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "api_validation" {
  for_each = {
    for dvo in aws_acm_certificate.api_validation.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = aws_route53_zone.this.zone_id
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300 # 5 m
  type            = each.value.type
  zone_id         = aws_route53_zone.this.zone_id
}

resource "aws_acm_certificate_validation" "api_validation" {
  count                   = data.external.get_ns_primary.result.nameservers == "" ? 0 : 1
  depends_on              = [aws_route53_record.api_validation]
  certificate_arn         = aws_acm_certificate.api_validation.arn
  validation_record_fqdns = [for record in aws_route53_record.api_validation : record.fqdn]
  timeouts {
    create = "10m"
  }
}
