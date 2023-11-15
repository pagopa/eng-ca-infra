path "intermediate-04/sign-verbatim/client-certificate" {
    capabilities = ["create", "update"]
}
path "intermediate-04/revoke" {
    capabilities = ["create", "update"]
}
path "intermediate-04/certs" {
    capabilities = ["list"]
}
path "intermediate-04/cert/*" {
    capabilities = ["read"]
}