## Usage
```hcl
provider "aws" {
  region = "us-east-1"
}

module "ec2-scheduled-stop" {
  source = "./ec2-scheduled-stop-start"

  lambda_name       = "ec2-scheduled-stop"
  region            = "us-east-1"
  aws_regions       = ["us-east-1", "us-west-2"]
  ec2_desired_state = "stopped"
  ec2_tag           = "NightlyRestart"
  schedule_cron     = "0 1 * * ? *"
}

module "ec2-scheduled-start" {
  source = "./ec2-scheduled-stop-start"

  lambda_name       = "ec2-scheduled-start"
  region            = "us-east-1"
  aws_regions       = ["us-east-1", "us-west-2"]
  ec2_desired_state = "running"
  ec2_tag           = "NightlyRestart"
  schedule_cron     = "0 12 * * ? *"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| lambda_name | Name of the Lambda. | string | ec2-scheduled-stop-start | no |
| region | The region to deploy the Lambda to. | string | us-east-1 | no |
| aws_regions | A comma-separated list of regions to check for instances. | list | ["us-east-1"] | no |
| ec2_desired_state | The desired instance state (running|stopped). | string | stopped | no |
| ec2_tag | The tag used to identify that an instance should be started/stopped. | string | NightlyRestart | no |
| schedule_cron | A cron describing the schedule this job should run on. | string | - | yes |


