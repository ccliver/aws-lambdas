locals {
  lambda_file_name = "${var.lambda_name}.py"
  lambda_zip       = "${var.lambda_name}.zip"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/${local.lambda_file_name}"
  output_path = "${path.module}/${local.lambda_zip}"
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
  description = "Grant DynamoDB CreateBackup for ${var.lambda_name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GrantDynamoDBPermissions",
      "Action": [
        "dynamodb:CreateBackup"
      ],
      "Effect": "Allow",
      "Resource": "*"
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
  filename         = "${path.module}/${local.lambda_zip}"
  function_name    = var.lambda_name
  role             = aws_iam_role.lambda.arn
  handler          = "${replace(local.lambda_file_name, ".py", "")}.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.7"
  timeout          = 60

  environment {
    variables = {
      DYNAMODB_TABLES = var.dynamodb_tables
    }
  }
}

resource "aws_lambda_permission" "lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda.arn
}

resource "aws_cloudwatch_event_rule" "lambda" {
  name                = var.lambda_name
  schedule_expression = "cron(${var.schedule_cron})"
}

resource "aws_cloudwatch_event_target" "lambda" {
  target_id = var.lambda_name
  rule      = aws_cloudwatch_event_rule.lambda.name
  arn       = aws_lambda_function.lambda.arn
}
