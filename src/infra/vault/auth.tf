## GitHub IDP
resource "vault_github_auth_backend" "this" {
  organization = "pagopa"
  token_type   = "batch"
  token_ttl    = "300"
}

## delegated users

### pietro.stroia@pagopa.it
resource "vault_github_user" "pp-ps" {
  backend = vault_github_auth_backend.this.id
  user    = "pp-ps"
  policies = [
    "intermediate-01-client-policy",
    "intermediate-03-client-policy",
    "intermediate-04-client-policy",
    "intermediate-05-client-policy"
  ]
}

### giuseppe.montesano@pagopa.it
resource "vault_github_user" "GiuMontesano" {
  backend = vault_github_auth_backend.this.id
  user    = "GiuMontesano"
  policies = [
    "intermediate-01-client-policy",
    "intermediate-03-client-policy",
    "intermediate-04-client-policy",
    "intermediate-05-client-policy"
  ]
}

### tommaso.lencioni@pagopa.it
resource "vault_github_user" "TommasoLencioni" {
  backend  = vault_github_auth_backend.this.id
  user     = "TommasoLencioni"
  policies = ["intermediate-04-client-policy", "intermediate-05-client-policy"]
}

### alessio.carpitelli@pagopa.it
resource "vault_github_user" "AlessioCarpitelli" {
  backend  = vault_github_auth_backend.this.id
  user     = "AlessioCarpitelli"
  policies = ["intermediate-04-client-policy", "intermediate-05-client-policy"]
}

#### giovanni.mancini@pagopa.it
resource "vault_github_user" "GiovanniMancini" {
  backend  = vault_github_auth_backend.this.id
  user     = "GiovanniMancini"
  policies = ["intermediate-04-client-policy", "intermediate-05-client-policy"]
}

#### marco.degregorio@pagopa.it
resource "vault_github_user" "mdegrego" {
  backend  = vault_github_auth_backend.this.id
  user     = "mdegrego"
  policies = ["intermediate-04-client-policy", "intermediate-05-client-policy"]
}

#### carlotta.bartoloni@pagopa.it
resource "vault_github_user" "carlottabartoloni" {
  backend  = vault_github_auth_backend.this.id
  user     = "carlottabartoloni"
  policies = ["intermediate-04-client-policy", "intermediate-05-client-policy"]
}

#### alessandro.lopez@pagopa.it
resource "vault_github_user" "Ale90l" {
  backend  = vault_github_auth_backend.this.id
  user     = "Ale90l"
  policies = ["intermediate-04-client-policy", "intermediate-05-client-policy"]
}

#### raimondo.castino@pagopa.it
resource "vault_github_user" "raicastino" {
  backend  = vault_github_auth_backend.this.id
  user     = "raicastino"
  policies = ["intermediate-04-client-policy", "intermediate-05-client-policy"]
}

##

## internal userpass auth (used only for automatic CRL rotation)
resource "vault_auth_backend" "userpass" {
  type  = "userpass"
  path  = "userpass"
  local = true
  tune = [{
    allowed_response_headers     = [""]
    audit_non_hmac_request_keys  = [""]
    audit_non_hmac_response_keys = [""]
    default_lease_ttl            = "300s"
    listing_visibility           = "hidden"
    max_lease_ttl                = "300s"
    passthrough_request_headers  = [""]
    token_type                   = "batch"
  }]
}

resource "vault_generic_endpoint" "crl-renewer" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/crl-renewer"
  ignore_absent_fields = true
  data_json            = <<EOD
  {
    "policies": ["rotate-crl-policy"],
    "password": "${data.aws_ssm_parameter.crl_renewer_password.value}"
  }
  EOD
}

