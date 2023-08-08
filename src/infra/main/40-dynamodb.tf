# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "vault-data"

resource "aws_dynamodb_table" "vault-data" {

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
