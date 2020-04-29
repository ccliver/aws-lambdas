provider "aws" {
  region = "us-east-1"
}

module "ec2-scheduled-stop" {
  source = "../modules/ec2-scheduled-stop-start"

  lambda_name       = "ec2-scheduled-stop"
  region            = "us-east-1"
  aws_regions       = ["us-east-1", "us-west-2"]
  ec2_desired_state = "stopped"
  ec2_tag           = "NightlyRestart"
  schedule_cron     = "0 1 * * ? *"
}

module "ec2-scheduled-start" {
  source = "../modules/ec2-scheduled-stop-start"

  lambda_name       = "ec2-scheduled-start"
  region            = "us-east-1"
  aws_regions       = ["us-east-1", "us-west-2"]
  ec2_desired_state = "running"
  ec2_tag           = "NightlyRestart"
  schedule_cron     = "0 12 * * ? *"
}
