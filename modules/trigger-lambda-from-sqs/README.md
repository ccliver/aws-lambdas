## Usage
```hcl
provider "aws" {
  region = "us-east-1"
}

module "trigger-lambda-from-sqs" {
  source = "../modules/trigger-lambda-from-sqs"

  dynamodb_table_name = "messages"
}
```

## Providers

| Name | Version |
|------|---------|
| archive | n/a |
| aws | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| dynamodb\_table\_name | Name of the DynamoDB table to store message data in | `string` | `"messages"` | no |
| lambda\_name | Name of the Lambda. | `string` | `"record-messages"` | no |
| sqs\_queue\_name | Name of the SQS queue that the Lambda will read messages from | `string` | `"messages"` | no |
