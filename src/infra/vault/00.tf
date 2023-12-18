#
# PagoPA Root CA - 00
# Security Team
#

resource "vault_mount" "root" {
  path                      = "root"
  type                      = "pki"
  default_lease_ttl_seconds = "157680000" # 5y
  max_lease_ttl_seconds     = "315360000" # 10y max
}

resource "vault_pki_secret_backend_config_urls" "root" {
  backend                 = vault_mount.root.path
  issuing_certificates    = ["https://${var.app_primary_domain_name}/00/ca"]
  crl_distribution_points = ["https://${var.app_primary_domain_name}/00/crl"]
}

resource "vault_pki_secret_backend_crl_config" "root" {
  backend = vault_mount.root.path
  expiry  = "24h"
  disable = false
}

resource "vault_pki_secret_backend_root_cert" "root" {
  depends_on           = [vault_mount.root]
  backend              = vault_mount.root.path
  type                 = "internal"
  common_name          = "PagoPA Root CA"
  key_type             = "rsa"
  key_bits             = 4096
  country              = "IT"
  locality             = "Rome"
  province             = "RM"
  organization         = "PagoPA S.p.A."
  ou                   = "Security Engineering"
  exclude_cn_from_sans = true
  format               = "pem"
  ttl                  = "315360000"
  lifecycle {
    prevent_destroy = true
  }
}