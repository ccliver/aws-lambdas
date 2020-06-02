locals {
  lambda_file_name = "${var.lambda_name}.py"
  lambda_zip       = "${var.lambda_name}.zip"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda/${local.lambda_zip}"
}

resource "aws_dynamodb_table" "faces" {
  name     = var.faces_table_name
  hash_key = "fileName"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "fileName"
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
      "Sid": "S3",
      "Action": [
        "s3:GetObject",
        "s3:HeadObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.source.id}/*"
    },
    {
      "Sid": "Rekognition",
      "Action": "rekognition:RecognizeCelebrities",
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Sid": "DynamoDB",
      "Action": "dynamodb:PutItem",
      "Effect": "Allow",
      "Resource": "${aws_dynamodb_table.faces.arn}"
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

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.source.arn
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
      DYNAMODB_TABLE = var.faces_table_name
    }
  }
}

resource "random_uuid" "source" {}

resource "aws_s3_bucket" "source" {
  bucket = "${var.source_bucket_prefix}-${random_uuid.source.result}"
  acl    = "public-read"
}

resource "aws_s3_bucket_notification" "source_notification" {
  bucket = aws_s3_bucket.source.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}
