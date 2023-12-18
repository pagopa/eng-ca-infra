#
# PagoPA Intermediate CA - 04
# CSTAR - UAT
#

resource "vault_mount" "int_04" {
  path                      = "intermediate-04"
  type                      = "pki"
  default_lease_ttl_seconds = "31536000"  # 1y
  max_lease_ttl_seconds     = "157680000" # 5y max
}

resource "vault_pki_secret_backend_config_urls" "int_04" {
  backend                 = vault_mount.int_04.path
  issuing_certificates    = ["https://${var.app_primary_domain_name}/intermediate/04/ca"]
  crl_distribution_points = ["https://${var.app_primary_domain_name}/intermediate/04/crl"]
}

resource "vault_pki_secret_backend_crl_config" "int_04" {
  backend = vault_mount.int_04.path
  expiry  = "24h"
  disable = false
}

resource "vault_pki_secret_backend_intermediate_cert_request" "int_04" {
  depends_on           = [vault_mount.int_04]
  backend              = vault_mount.int_04.path
  type                 = "internal"
  common_name          = "PagoPA Intermediate CA - 04"
  key_type             = "rsa"
  key_bits             = 3072
  country              = "IT"
  locality             = "Rome"
  province             = "RM"
  organization         = "PagoPA S.p.A."
  ou                   = "Security Engineering"
  exclude_cn_from_sans = true
  lifecycle {
    prevent_destroy = true
  }

}

resource "vault_pki_secret_backend_root_sign_intermediate" "int_04" {
  depends_on  = [vault_pki_secret_backend_intermediate_cert_request.int_04, vault_mount.root]
  backend     = vault_mount.root.path
  csr         = vault_pki_secret_backend_intermediate_cert_request.int_04.csr
  common_name = "PagoPA Intermediate CA - 04"
  format      = "pem"
}

resource "vault_pki_secret_backend_intermediate_set_signed" "int_04" {
  depends_on  = [vault_pki_secret_backend_root_sign_intermediate.int_04, vault_mount.int_04]
  backend     = vault_mount.int_04.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.int_04.certificate
}

# create a role for signing CRL, specific for a client-certificate output
resource "vault_pki_secret_backend_role" "int_04_client" {
  depends_on = [vault_mount.int_04]
  backend    = vault_mount.int_04.path
  name       = "client-certificate" # role name, used by the frontend for the sign-verbatim call
  # config
  ttl                                = "15768000" # 6m
  max_ttl                            = "31536000" # 1y
  allow_any_name                     = true
  enforce_hostnames                  = false
  key_type                           = "rsa"
  key_bits                           = 2048
  basic_constraints_valid_for_non_ca = true
  server_flag                        = false
  ext_key_usage                      = ["ClientAuth"]
  key_usage                          = ["DigitalSignature"]
  use_csr_common_name                = true
  use_csr_sans                       = false
  require_cn                         = true
}