locals {
  lambda_file_name = "${var.lambda_name}.py"
  lambda_zip       = "${var.lambda_name}.zip"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda/${local.lambda_zip}"
}

resource "aws_dynamodb_table" "messages" {
  name         = var.dynamodb_table_name
  hash_key     = "messageId"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "messageId"
    type = "S"
  }
}

resource "aws_iam_role" "lambda" {
  name = var.lambda_name

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

resource "aws_iam_policy" "lambda" {
  name        = var.lambda_name
  path        = "/"
  description = "Grant S3 access for ${var.lambda_name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DynamoDB",
      "Action": "dynamodb:PutItem",
      "Effect": "Allow",
      "Resource": "${aws_dynamodb_table.messages.arn}"
    },
    {
      "Sid": "SQS",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Effect": "Allow",
      "Resource": "${aws_sqs_queue.messages.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "lambda" {
  name       = var.lambda_name
  roles      = ["${aws_iam_role.lambda.name}"]
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_iam_policy_attachment" "lambda_basic_execution" {
  name       = "AWSLambdaBasicExecutionRole"
  roles      = ["${aws_iam_role.lambda.name}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lambda" {
  filename         = "${path.module}/lambda/${local.lambda_zip}"
  function_name    = var.lambda_name
  role             = aws_iam_role.lambda.arn
  handler          = "${replace(local.lambda_file_name, ".py", "")}.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.6"
  timeout          = 60

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }
}

resource "aws_sqs_queue" "messages" {
  name = var.sqs_queue_name
  visibility_timeout_seconds = 60
}

resource "aws_lambda_event_source_mapping" "messages" {
  event_source_arn = "${aws_sqs_queue.messages.arn}"
  function_name    = "${aws_lambda_function.lambda.arn}"
}
