locals {
  lambda_file_name = "${var.lambda_name}.py"
  lambda_zip       = "${var.lambda_name}.zip"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
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
  description = "Grant S3 and Dynamodb access for ${var.lambda_name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GetCSVData",
      "Action": [
        "s3:GetObject",
        "s3:HeadObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.incoming_csv.id}/*"
    },
    {
      "Sid": "WriteCSVData",
      "Action": [
        "dynamodb:BatchWriteItem"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:dynamodb:*:*:table/${aws_dynamodb_table.movies.id}"
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
  source_arn    = aws_s3_bucket.incoming_csv.arn
}

resource "aws_lambda_function" "lambda" {
  filename         = "${path.module}/${local.lambda_zip}"
  function_name    = var.lambda_name
  role             = aws_iam_role.lambda.arn
  handler          = "${replace(local.lambda_file_name, ".py", "")}.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout

  environment {
    variables = {
      INCOMING_CSV_BUCKET = aws_s3_bucket.incoming_csv.id
      TABLE_NAME          = aws_dynamodb_table.movies.id
    }
  }
}

resource "random_uuid" "source" {}

resource "aws_s3_bucket" "incoming_csv" {
  bucket = "${var.source_bucket_prefix}-${random_uuid.source.result}"
  acl    = "public-read"
}

resource "aws_s3_bucket_notification" "source_notification" {
  bucket = aws_s3_bucket.incoming_csv.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

resource "aws_dynamodb_table" "movies" {
  name           = "movies"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "Year"
  range_key      = "Title"

  attribute {
    name = "Year"
    type = "N"
  }

  attribute {
    name = "Title"
    type = "S"
  }

  tags = {
    Name = "movies"
  }
}
