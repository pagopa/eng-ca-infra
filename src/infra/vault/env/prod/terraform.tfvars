env_short   = "p"
environment = "prod"

aws_region = "eu-south-1"

# dns
app_primary_domain_name    = "ca.eng.pagopa.it"
api_primary_domain_name  = "api.ca.eng.pagopa.it"

# Ref: https://pagopa.atlassian.net/wiki/spaces/DEVOPS/pages/132810155/Azure+-+Naming+Tagging+Convention#Tagging
tags = {
  CreatedBy   = "Terraform"
  Environment = "Prod"
  Owner       = "ppa-eng-ca"
  Source      = "https://github.com/pagopa/eng-ca"
  CostCenter  = "tier0"
}
