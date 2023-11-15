resource "vault_policy" "rotate_crl" {
  name   = "rotate-crl-policy"
  policy = file("policies/rotate-crl-policy.hcl")
}

resource "vault_policy" "int_01_client" {
  name   = "intermediate-01-client-policy"
  policy = file("policies/intermediate-01-client-policy.hcl")
}

resource "vault_policy" "int_03_client" {
  name   = "intermediate-03-client-policy"
  policy = file("policies/intermediate-03-client-policy.hcl")
}

resource "vault_policy" "int_04_client" {
  name   = "intermediate-04-client-policy"
  policy = file("policies/intermediate-04-client-policy.hcl")
}

resource "vault_policy" "int_05_client" {
  name   = "intermediate-05-client-policy"
  policy = file("policies/intermediate-05-client-policy.hcl")
}
