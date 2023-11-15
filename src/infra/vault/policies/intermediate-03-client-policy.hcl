path "intermediate-03/sign-verbatim/client-certificate" {
    capabilities = ["create", "update"]
}
path "intermediate-03/revoke" {
    capabilities = ["create", "update"]
}
path "intermediate-03/certs" {
    capabilities = ["list"]
}
path "intermediate-03/cert/*" {
    capabilities = ["read"]
}