variable "lambda_name" {
  type = string
  description = "Name of the Lambda."
  default = "deregister-old-amis"
}

variable "region" {
  type = string
  description = "The region to deploy the Lambda to."
  default = "us-east-1"
}

variable "aws_regions" {
  description = "A comma-separated list of regions to check for AMIs."
  type = list
  default = ["us-east-1"]
}

variable "ami_tag" {
  description = "The tag used to identify that an AMI should be garbage collected."
  type = string
  default = "Deletable"
}

variable "schedule_cron" {
  description = "A cron describing the schedule this job should run on."
  type = string
}

variable "lambda_timeout" {
  description = "TTL for the Lambda function in seconds (max 15 minutes)"
  type = number
  default = 300
}

variable "max_days" {
  description = "Max number of days to keep an AMI before deregistering it."
  type = number
  default = 14
}
