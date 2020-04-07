## Usage
```hcl
provider "aws" {
  region = "us-east-1"
}

module "dynamodb_backup" {
  source = "./dynamodb-backup"

  lambda_name     = "dynamodb-backup"
  schedule_cron   = "0 1 * * ? *"
  dynamodb_tables = "table1,table2"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| dynamodb\_tables | Comma-separated list of DynamoDB tables to backup | `string` | n/a | yes |
| lambda\_name | Name of the Lambda. | `string` | `"dynamodb-backup"` | no |
| schedule\_cron | A cron describing the schedule this job should run on. | `string` | n/a | yes |

## Outputs

No output.
