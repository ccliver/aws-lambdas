## Usage
```hcl
provider "aws" {
  region = "us-east-1"
}

module "transcribe-audio" {
  source = "../modules/transcribe-audio"

  audio_bucket_prefix          = "audio-files"
  transcription_bucket_prefix  = "transcribed-files"
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
| audio\_bucket\_prefix | Descriptive prefix to use for the bucket that holds audio recordings | `string` | `"audio-files"` | no |
| parse\_lambda\_name | Name of the transcription parsing Lambda. | `string` | `"parse-transcriptions"` | no |
| transcribe\_lambda\_name | Name of the transcription Lambda. | `string` | `"transcribe-audio"` | no |
| transcription\_bucket\_prefix | Descriptive prefix to use for the bucket that holds transcribed audio files | `string` | `"transcriptions"` | no |
