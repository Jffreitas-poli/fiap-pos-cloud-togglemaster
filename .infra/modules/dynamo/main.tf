# Dynamo_DB
resource "aws_dynamodb_table" "dynamo" {
  name         = "tc-${var.env}-dynamo"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"
  attribute {
    name = "event_id"
    type = "S"
  }
  tags = {
    Environment = var.env
  }
}