## Usage
```hcl
provider "aws" {
  region = "us-east-1"
}

module "resizing-images" {
  source = "../modules/resizing-images"

  source_bucket_prefix    = "full-size-images"
  thumbnail_bucket_prefix = "thumbnail-images"
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
| lambda\_name | Name of the Lambda. | `string` | `"resize-images"` | no |
| source\_bucket\_prefix | Descriptive prefix to use for the source bucket name | `string` | `"source-images"` | no |
| thumbnail\_bucket\_prefix | Descriptive prefix to use for the thumbnail bucket name | `string` | `"thumbnail-images"` | no |
| thumbnail\_height | The height of thumbnail images | `number` | `128` | no |
| thumbnail\_width | The width of thumbnail images | `number` | `128` | no |
