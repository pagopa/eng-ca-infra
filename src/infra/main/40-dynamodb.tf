# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "vault_data"

resource "aws_dynamodb_table" "vault_data" {

  billing_mode                = "PROVISIONED"
  deletion_protection_enabled = false
  hash_key                    = "Path"
  name                        = "vault-data"

  range_key              = "Key"
  read_capacity          = 5
  restore_date_time      = null
  restore_source_name    = null
  restore_to_latest_time = null
  stream_enabled         = false
  stream_view_type       = null
  table_class            = "STANDARD"


  write_capacity = 5
  attribute {
    name = "Key"
    type = "S"
  }
  attribute {
    name = "Path"
    type = "S"
  }
  point_in_time_recovery {
    enabled = false
  }
  ttl {
    attribute_name = ""
    enabled        = false
  }
}

## DynamoDB table for certification information storage (Expiring Cert. Checker)
resource "aws_dynamodb_table" "certificate_information" {
  name = "ca-eng-pagopa-it-cert-expiry-info"

  attribute {
    name = "SER"
    type = "S"
  }

  attribute {
    name = "INT"
    type = "S"
  }

  attribute {
    name = "NVA"
    type = "N"
  }

  hash_key     = "SER"
  billing_mode = "PAY_PER_REQUEST"

  global_secondary_index {
    name            = "secondary-index"
    hash_key        = "INT"
    range_key       = "NVA"
    projection_type = "ALL"
  }

  lifecycle {
    prevent_destroy = false
  }

  point_in_time_recovery {
    enabled = true
  }

  # enabled = false is explicit about using a AWS owned CMK for the encryption at rest,
  # instead of using a AWS managed CMK or a Customer Manager CMK
  server_side_encryption {
    enabled = true
  }

}
