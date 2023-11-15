path "intermediate-01/sign-verbatim/client-certificate" {
    capabilities = ["create", "update"]
}
path "intermediate-01/revoke" {
    capabilities = ["create", "update"]
}
path "intermediate-01/certs" {
    capabilities = ["list"]
}
path "intermediate-01/cert/*" {
    capabilities = ["read"]
}