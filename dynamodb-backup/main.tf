provider "aws" {
  region = "us-east-1"
}

module "dynamodb_backup" {
  source = "../modules/dynamodb-backup"

  lambda_name     = "dynamodb-backup"
  schedule_cron   = "0 1 * * ? *"
  dynamodb_tables = "table1,table2"
}
