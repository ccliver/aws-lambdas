## Usage
```hcl
provider "aws" {
  region = "us-east-1"
}

module "csv-import-to-dynamodb" {
  source = "./csv-import-to-dynamodb"

  source_bucket_prefix = "incoming-csv-files"
}
```
## Providers

| Name | Version |
|------|---------|
| archive | n/a |
| aws | n/a |
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| lambda\_name | Name of the Lambda. | `string` | `"csv-import-to-dynamodb"` | no |
| lambda\_runtime | The Lambda's runtime environment | `string` | `"python3.6"` | no |
| lambda\_timeout | Max running time for the lambda | `number` | `60` | no |
| source\_bucket\_prefix | Descriptive prefix to use for the source bucket name | `string` | `"incoming-csv-files"` | no |

## Outputs

No output.
