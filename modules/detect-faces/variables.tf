variable "lambda_name" {
  description = "Name of the Lambda."
  default     = "detect-faces"
}

variable "source_bucket_prefix" {
  description = "Descriptive prefix to use for the source bucket name"
  default     = "source-images"
}

variable "faces_table_name" {
  description = "Name of the DynamoDB table to store face data"
  default     = "faces"
}
