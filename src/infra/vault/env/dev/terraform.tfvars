env_short   = "d"
environment = "dev"

# dns
app_primary_domain_name  = "dev.ca.eng.pagopa.it"

# Ref: https://pagopa.atlassian.net/wiki/spaces/DEVOPS/pages/132810155/Azure+-+Naming+Tagging+Convention#Tagging
tags = {
  CreatedBy   = "Terraform"
  Environment = "Dev"
  Owner       = "ppa-eng-ca"
  Source      = "https://github.com/pagopa/eng-ca"
  CostCenter  = "tier0"
}
