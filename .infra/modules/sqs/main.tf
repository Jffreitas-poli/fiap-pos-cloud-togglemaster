resource "aws_sqs_queue" "sqs" {
  name                      = "tc-${var.env}-sqs"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 60
  receive_wait_time_seconds = 10
  tags = {
    Environment = var.env
  }
}
