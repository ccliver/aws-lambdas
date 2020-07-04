locals {
  lambda_file_name = "${var.lambda_name}.py"
  lambda_zip       = "${var.lambda_name}.zip"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda/${local.lambda_zip}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  version            = "2.38.0"
  name               = "app-vpc"
  cidr               = "10.0.0.0/16"
  azs                = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway = true

  vpc_tags = {
    Name = "app-vpc"
  }
}

resource "aws_iam_role" "app" {
  name = var.lambda_name
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "ssm_access" {
  name       = "${var.lambda_name}-ssm-access"
  roles      = [aws_iam_role.app.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_instance_profile" "app" {
  name = var.lambda_name
  role = aws_iam_role.app.name
}

resource "aws_security_group" "app" {
  name   = var.lambda_name
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  # Use an old AMI that will trigger Inspector
  filter {
    name   = "name"
    values = ["amzn-ami-hvm-2018*"]
  }

  owners = ["137112412989"] # AWS
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "aws_key_pair" "app" {
  key_name   = "app"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.medium"
  vpc_security_group_ids = [aws_security_group.app.id]
  subnet_id              = module.vpc.public_subnets[0]
  key_name               = aws_key_pair.app.key_name
  iam_instance_profile   = aws_iam_instance_profile.app.name

  root_block_device {
    volume_type  = "gp2"
  }

  user_data              = <<EOF
#!/bin/bash
bash -c "$(curl -fsSL https://inspector-agent.amazonaws.com/linux/latest/install)"
EOF

  tags = {
    Name = "app"
    Env  = "production"
  }
}

resource "aws_iam_role" "lambda" {
  name = "${var.lambda_name}-lambda"

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

resource "aws_iam_policy_attachment" "lambda_execution" {
  name       = "AWSLambdaBasicExecutionRole"
  roles      = ["${aws_iam_role.lambda.name}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy_attachment" "ssm" {
  name       = "AmazonSSMFullAccess"
  roles      = ["${aws_iam_role.lambda.name}"]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_policy" "inspector" {
  name        = "${var.lambda_name}-inspector"
  path        = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "inspector:DescribeFindings"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "inspector" {
  name       = "${var.lambda_name}-inspector"
  roles      = ["${aws_iam_role.lambda.name}"]
  policy_arn = aws_iam_policy.inspector.arn
}

resource "aws_sns_topic" "inspector" {
  name = var.lambda_name
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.inspector.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda.arn
}

resource "aws_lambda_function" "lambda" {
  filename         = "${path.module}/lambda/${local.lambda_zip}"
  function_name    = var.lambda_name
  role             = aws_iam_role.lambda.arn
  handler          = "${replace(local.lambda_file_name, ".py", "")}.lambda_handler"
  runtime          = "python3.6"
  source_code_hash = data.archive_file.lambda.output_base64sha256
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.inspector.arn
}

resource "aws_inspector_resource_group" "prod" {
  tags = {
    Env  = "production"
  }
}

resource "aws_inspector_assessment_target" "prod" {
  name               = var.lambda_name
  resource_group_arn = aws_inspector_resource_group.prod.arn
}

data "aws_inspector_rules_packages" "rules" {}

resource "aws_inspector_assessment_template" "assessment" {
  name       = var.lambda_name
  target_arn = "${aws_inspector_assessment_target.prod.arn}"
  duration   = "180"

  rules_package_arns = data.aws_inspector_rules_packages.rules.arns
}
