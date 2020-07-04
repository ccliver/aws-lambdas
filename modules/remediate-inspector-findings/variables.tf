variable "lambda_name" {
  description = "Name of the Lambda."
  default     = "remediate-inspector-findings"
}

variable "region" {
  description = "AWS region to deploy the lambda to"
  default     = "us-east-1"
}
