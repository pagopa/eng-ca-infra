## Mandatory for Frontend function
data "aws_ssm_parameter" "vault_active_address" {
  name = "ca.eng-vault_active_address"
}

#This SSM parameter contains the Slack webhook
data "aws_ssm_parameter" "slack_webhook" {
  name = "ca.eng-slack_webhook"
}

##
## These SSM parameters contain the SMTP credentials 
## and will be created only in the prod environment.
## Mandatory for Notification Handler function.
##
data "aws_ssm_parameter" "smtp_username" {
  count = var.environment == "prod" ? 1 : 0
  name  = "ca.eng-smtp_username"
}

data "aws_ssm_parameter" "smtp_password" {
  count = var.environment == "prod" ? 1 : 0
  name  = "ca.eng-smtp_password"
}


