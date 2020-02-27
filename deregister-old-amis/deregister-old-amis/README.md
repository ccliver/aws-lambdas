## Usage
```hcl
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
}
```

## Providers

| Name | Version |
|------|---------|
| archive | n/a |
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| ami\_tag | The tag used to identify that an AMI should be garbage collected. | `string` | `"Deletable"` | no |
| aws\_regions | A comma-separated list of regions to check for AMIs. | `list` | <pre>[<br>  "us-east-1"<br>]</pre> | no |
| lambda\_name | Name of the Lambda. | `string` | `"deregister-old-amis"` | no |
| lambda\_timeout | TTL for the Lambda function in seconds (max 15 minutes) | `number` | `300` | no |
| max\_days | Max number of days to keep an AMI before deregistering it. | `number` | `14` | no |
| region | The region to deploy the Lambda to. | `string` | `"us-east-1"` | no |
| schedule\_cron | A cron describing the schedule this job should run on. | `string` | n/a | yes |

## Outputs

No output.

