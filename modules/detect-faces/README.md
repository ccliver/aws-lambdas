## Usage
```hcl
provider "aws" {
  region = "us-east-1"
}

module "detect-faces" {
  source = "../modules/detect-faces"

  source_bucket_prefix = "images"
  faces_table_name     = "faces-from-images"
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
|------|-------------|------|---------|:--------:|
| faces\_table\_name | Name of the DynamoDB table to store face data | `string` | `"faces"` | no |
| lambda\_name | Name of the Lambda. | `string` | `"detect-faces"` | no |
| source\_bucket\_prefix | Descriptive prefix to use for the source bucket name | `string` | `"source-images"` | no |
