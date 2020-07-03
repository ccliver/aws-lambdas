## Usage
```hcl
module "respond-to-invalid-ssh-logins" {
  source = "../modules/respond-to-invalid-ssh-logins"

  region = "us-east-1"
}
```

## Providers

| Name | Version |
|------|---------|
| archive | n/a |
| aws | n/a |
| tls | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| lambda\_name | Name of the Lambda. | `string` | `"respond-to-invalid-ssh-logins"` | no |
| region | AWS region for the Cloudwatch agent config | `string` | `"us-east-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| public\_ip | n/a |
| ssh\_private\_key | n/a |
