locals {
  transcribe_lambda_file_name = "${var.transcribe_lambda_name}.py"
  transcribe_lambda_zip       = "${var.transcribe_lambda_name}.zip"
  parse_lambda_file_name      = "${var.parse_lambda_name}.py"
  parse_lambda_zip            = "${var.parse_lambda_name}.zip"
}

data "archive_file" "transcribe_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda/${local.transcribe_lambda_zip}"
}

data "archive_file" "parse_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda/${local.parse_lambda_zip}"
}

resource "aws_iam_role" "transcribe_lambda" {
  name = var.transcribe_lambda_name

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

resource "aws_iam_role" "parse_lambda" {
  name = var.parse_lambda_name

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

resource "aws_iam_policy" "transcribe_lambda" {
  name        = var.transcribe_lambda_name
  path        = "/"
  description = "Grant access for Lambda ${var.transcribe_lambda_name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GetImages",
      "Action": [
        "s3:GetObject",
        "s3:HeadObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.audio_files.id}/*"
    },
    {
      "Sid": "TranscribeAudio",
      "Action": [
        "transcribe:StartTranscriptionJob"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "parse_lambda" {
  name        = var.parse_lambda_name
  path        = "/"
  description = "Grant access for Lambda ${var.parse_lambda_name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GetImages",
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.transcriptions.id}/*"
    },
    {
      "Sid": "GetTranscriptions",
      "Action": [
        "transcribe:GetTranscriptionJob"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "transcribe_lambda" {
  name       = var.transcribe_lambda_name
  roles      = ["${aws_iam_role.transcribe_lambda.name}"]
  policy_arn = aws_iam_policy.transcribe_lambda.arn
}

resource "aws_iam_policy_attachment" "parse_lambda" {
  name       = var.parse_lambda_name
  roles      = ["${aws_iam_role.parse_lambda.name}"]
  policy_arn = aws_iam_policy.parse_lambda.arn
}

resource "aws_iam_policy_attachment" "transcribe_lambda_execution" {
  name       = "AWSLambdaBasicExecutionRole"
  roles      = ["${aws_iam_role.transcribe_lambda.name}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy_attachment" "parse_lambda_execution" {
  name       = "AWSLambdaBasicExecutionRole"
  roles      = ["${aws_iam_role.parse_lambda.name}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_permission" "transcriptions" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.transcribe_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.audio_files.arn
}

resource "aws_lambda_function" "transcribe_lambda" {
  filename         = "${path.module}/lambda/${local.transcribe_lambda_zip}"
  function_name    = var.transcribe_lambda_name
  role             = aws_iam_role.transcribe_lambda.arn
  handler          = "${replace(local.transcribe_lambda_file_name, ".py", "")}.lambda_handler"
  source_code_hash = data.archive_file.transcribe_lambda.output_base64sha256
  runtime          = "python3.6"
  timeout          = 60

  environment {
    variables = {
      S3_BUCKET  = aws_s3_bucket.audio_files.id
    }
  }
}

resource "random_uuid" "uuid" {}

resource "aws_s3_bucket" "audio_files" {
  bucket = "${var.audio_bucket_prefix}-${random_uuid.uuid.result}"
  acl    = "public-read"
}

resource "aws_s3_bucket" "transcriptions" {
  bucket = "${var.transcription_bucket_prefix}-${random_uuid.uuid.result}"
  acl    = "public-read"
}

resource "aws_s3_bucket_notification" "audio_notification" {
  bucket = aws_s3_bucket.audio_files.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.transcribe_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.transcriptions]
}

resource "aws_lambda_function" "parse_lambda" {
  filename         = "${path.module}/lambda/${local.parse_lambda_zip}"
  function_name    = var.parse_lambda_name
  role             = aws_iam_role.parse_lambda.arn
  handler          = "${replace(local.parse_lambda_file_name, ".py", "")}.lambda_handler"
  source_code_hash = data.archive_file.parse_lambda.output_base64sha256
  runtime          = "python3.6"
  timeout          = 60

  environment {
    variables = {
      S3_BUCKET  = aws_s3_bucket.transcriptions.id
    }
  }
}

resource "aws_lambda_permission" "parse_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.parse_lambda.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.transcribed.arn
}

resource "aws_cloudwatch_event_rule" "transcribed" {
  name        = var.parse_lambda_name
  description = "Trigger a lambda to parse transcribed audio"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.transcribe"
  ],
  "detail-type": [
    "Transcribe Job State Change"
  ],
  "detail": {
    "TranscriptionJobStatus": [
      "COMPLETED"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "lambda" {
  target_id = var.parse_lambda_name
  rule      = aws_cloudwatch_event_rule.transcribed.name
  arn       = aws_lambda_function.parse_lambda.arn
}
