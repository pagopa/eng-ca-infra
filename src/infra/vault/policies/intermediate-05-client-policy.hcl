path "intermediate-05/sign-verbatim/client-certificate" {
    capabilities = ["create", "update"]
}
path "intermediate-05/revoke" {
    capabilities = ["create", "update"]
}
path "intermediate-05/certs" {
    capabilities = ["list"]
}
path "intermediate-05/cert/*" {
    capabilities = ["read"]
}