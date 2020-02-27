provider "aws" {
  region = "us-east-1"
}

module "deregister-old-amis" {
  source = "./deregister-old-amis"

  lambda_name       = "deregister-old-amis"
  region            = "us-east-1"
  aws_regions       = ["us-east-1", "us-west-2"]
  ami_tag           = "Deletable"
  schedule_cron     = "0 1 * * ? *"
  max_days          = -1
}
