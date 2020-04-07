variable "lambda_name" {
  type        = string
  description = "Name of the Lambda."
  default     = "dynamodb-backup"
}

variable "dynamodb_tables" {
  description = "Comma-separated list of DynamoDB tables to backup"
  type        = string
}

variable "schedule_cron" {
  description = "A cron describing the schedule this job should run on."
  type        = string
}
