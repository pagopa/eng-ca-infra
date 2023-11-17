environment = "Prod"

create_backend = true
aws_region     = "eu-south-1"


tags = {
  "CreatedBy"   = "Terraform"
  "Environment" = "Prod"
  "Owner"       = "ppa-eng-ca"
  "Scope"       = "tfstate"
  "Source"      = "https://github.com/pagopa/eng-ca.git"
  "name"        = "S3 Remote Terraform State Store"
}