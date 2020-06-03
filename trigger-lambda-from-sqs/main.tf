provider "aws" {
  region = "us-east-1"
}

module "trigger-lambda-from-sqs" {
  source = "../modules/trigger-lambda-from-sqs"

  dynamodb_table_name = "messages"
}
