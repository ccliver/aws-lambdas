variable "lambda_name" {
  type = string
  description = "Name of the Lambda."
  default = "ec2-scheduled-stop-start"
}

variable "region" {
  type = string
  description = "The region to deploy the Lambda to."
  default = "us-east-1"
}

variable "aws_regions" {
  description = "A comma-separated list of regions to check for instances."
  type = list
  default = ["us-east-1"]
}

variable "ec2_desired_state" {
  descrption = "The desired instance state (running|stopped)."
  type = string
  default = "stopped"
}

variable "ec2_tag" {
  description = "The tag used to identify that an instance should be started/stopped."
  type = string
  default = "NightlyRestart"
}

variable "schedule_cron" {
  description = "A cron describing the schedule this job should run on."
  type = string
}
