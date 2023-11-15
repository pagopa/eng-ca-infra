# TODO could this be generated dynamically?

# read mount points
path "/sys/mounts" {
  capabilities = ["read"]
}

# Root CA
path "root/crl/rotate" {
  capabilities = ["read"]
}
path "root/tidy" {
  capabilities = ["update"]
}

# Intermediate 01
path "intermediate-01/crl/rotate" {
  capabilities = ["read"]
}

path "intermediate-01/tidy" {
  capabilities = ["update"]
}

# Intermediate 03
path "intermediate-03/crl/rotate" {
  capabilities = ["read"]
}

path "intermediate-03/tidy" {
  capabilities = ["update"]
}

# Intermediate 04
path "intermediate-04/crl/rotate" {
  capabilities = ["read"]
}

path "intermediate-04/tidy" {
  capabilities = ["update"]
}

# Intermediate 05
path "intermediate-05/crl/rotate" {
  capabilities = ["read"]
}

path "intermediate-05/tidy" {
  capabilities = ["update"]
}