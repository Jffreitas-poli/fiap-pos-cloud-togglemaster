resource "aws_sqs_queue" "sqs" {
  name                      = "tc-${var.env}-sqs"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = 300
  receive_wait_time_seconds = 0
  visibility_timeout_seconds = 300
  tags = {
    Environment = var.env
  }
}
