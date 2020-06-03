variable "lambda_name" {
  description = "Name of the Lambda."
  default     = "record-messages"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table to store message data in"
  default     = "messages"
}

variable "sqs_queue_name" {
  description = "Name of the SQS queue that the Lambda will read messages from"
  default     = "messages"
}
