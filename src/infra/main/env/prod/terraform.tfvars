env_short   = "p"
environment = "prod"

aws_region = "eu-south-1"
azs        = ["eu-south-1a", "eu-south-1b", "eu-south-1c"]

# dns
app_primary_domain_name  = "ca.eng.pagopa.it"
app_next_env_domain_name = "dummy"

vault_version = "1.14.7"

# Ref: https://pagopa.atlassian.net/wiki/spaces/DEVOPS/pages/132810155/Azure+-+Naming+Tagging+Convention#Tagging
tags = {
  CreatedBy   = "Terraform"
  Environment = "Prod"
  Owner       = "ppa-eng-ca"
  Source      = "https://github.com/pagopa/eng-ca-infra"
  CostCenter  = "tier0"
}
