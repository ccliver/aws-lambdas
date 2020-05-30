## Sample Lambda code for various tasks in AWS.
All Lambdas are deployed using Terraform and can be built with the Docker runner using Make targets. Most lambdas are implemented as Terraform modules in the `modules` folder and have usage/inputs/outputs documented in READMEs.

## Lambdas
| Lambda Name | Use Case |
| ----------- | -------- |
| ec2-scheduled-stop-start | Stop/start EC2 instances on a schedule |
| deregister-old-amis | Deregister unneeded AMIs based on tagging |
| enable-vpc-flow-logs | Enable VPC flow logs when any new VPCs are created |
| dynamodb-backup | Backup a DynamoDB table on a schedule |
| resizing-images | Create thumbnails of images uploaded to an S3 bucket |
| csv-import-to-dynamodb | Import CSV files uploaded to an S3 bucket into a DynamoDB table |
| transcribe-audio | Transcribe audio files uploaded to an S3 bucket with Amazon Transcribe. A second lambda parses out the transcription text and writes it to another S3 bucket|
  
## Usage
```bash
export PROJECT=ec2-scheduled-stop-start
make init
make plan
make apply
```

