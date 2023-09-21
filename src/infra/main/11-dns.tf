data "external" "get_ns_next" {
  program = ["bash", "./get_ns.sh", "${var.app_next_env_domain_name}.${var.app_primary_domain_name}"]
}

resource "aws_route53_zone" "this" {
  name = var.app_primary_domain_name
}

resource "aws_route53_record" "env_link" {
  count           = data.external.get_ns_next.result.nameservers == "" ? 0 : 1
  name            = var.app_next_env_domain_name
  records         = split(",", data.external.get_ns_next.result.nameservers)
  ttl             = 86400 # 24 h
  type            = "NS"
  zone_id         = aws_route53_zone.this.zone_id
  allow_overwrite = true
}

output "aws_route53_zone_this_ns" {
  value = aws_route53_zone.this.name_servers
}
