variable "lambda_name" {
  description = "Name of the Lambda."
  default     = "csv-import-to-dynamodb"
}

variable "source_bucket_prefix" {
  description = "Descriptive prefix to use for the source bucket name"
  default     = "incoming-csv-files"
}

variable "lambda_runtime" {
  description = "The Lambda's runtime environment"
  default     = "python3.6"
}

variable "lambda_timeout" {
  description = "Max running time for the lambda"
  default     = 60
}
