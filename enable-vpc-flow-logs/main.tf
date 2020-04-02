provider "aws" {
  region = "us-east-1"
}

locals {
  lambda_name      = "enable-vpc-flow-logs"
  lambda_file_name = "${local.lambda_name}.py"
  lambda_zip       = "${local.lambda_name}.zip"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/${local.lambda_file_name}"
  output_path = "${path.module}/${local.lambda_zip}"
}

resource "aws_iam_role" "lambda" {
  name = local.lambda_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "lambda" {
  filename         = "${path.module}/${local.lambda_zip}"
  function_name    = local.lambda_name
  role             = aws_iam_role.lambda.arn
  handler          = "${replace(local.lambda_file_name, ".py", "")}.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.7"
  timeout          = 30
}

resource "aws_lambda_permission" "lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda.arn
}

resource "aws_cloudwatch_event_rule" "lambda" {
  name        = local.lambda_name
  description = "Trigger a lambda to turn on VPC Flow Logs when the CreateVpc API call is detected"

  event_pattern = <<PATTERN
{
    "source": [
        "aws.ec2"
    ],
    "detail-type": [
        "AWS API Call via CloudTrail"
    ],
    "detail": {
        "eventSource": [
            "ec2.amazonaws.com"
        ],
        "eventName": [
            "CreateVpc"
        ]
    }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "lambda" {
  target_id = local.lambda_name
  rule      = aws_cloudwatch_event_rule.lambda.name
  arn       = aws_lambda_function.lambda.arn
}
