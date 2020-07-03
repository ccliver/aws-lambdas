variable "lambda_name" {
  description = "Name of the Lambda."
  default     = "respond-to-invalid-ssh-logins"
}

variable "region" {
  description = "AWS region for the Cloudwatch agent config"
  default     = "us-east-1"
}
