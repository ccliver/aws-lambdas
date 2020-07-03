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

resource "aws_iam_role" "bastion" {
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

resource "aws_iam_policy_attachment" "bastion_cloudwatch_agent_admin" {
  name       = "bastion-cloudwatch-agent-admin"
  roles      = [aws_iam_role.bastion.name]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"
}

resource "aws_iam_policy_attachment" "bastion_ssm" {
  name       = "bastion-ssm"
  roles      = [aws_iam_role.bastion.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_instance_profile" "bastion" {
  name = var.lambda_name
  role = aws_iam_role.bastion.name
}

resource "aws_security_group" "bastion" {
  name   = "bastion"
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

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-2018.03*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # AWS
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "aws_key_pair" "bastion" {
  key_name   = "bastion"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.medium"
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = module.vpc.public_subnets[0]
  key_name               = aws_key_pair.bastion.key_name
  iam_instance_profile   = aws_iam_instance_profile.bastion.name
  ephemeral_block_device {
    device_name  = "/dev/xvdz"
    virtual_name = "ephemeral0"
  }
  user_data = <<SCRIPT
#!/bin/bash
mkdir /opt/awslogs
cd /opt/awslogs
curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O
chmod +x ./awslogs-agent-setup.py
echo '
[general]
state_file = /var/awslogs/state/agent-state  
 
[/var/log/messages]
file = /var/log/secure
log_group_name = /var/log/secure
log_stream_name = {instance_id}
datetime_format = %b %d %H:%M:%S
' > /opt/awslogs/awslogs-agent-config
./awslogs-agent-setup.py -n -r ${var.region} -c /opt/awslogs/awslogs-agent-config
SCRIPT

  tags = {
    Name = "bastion"
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

resource "aws_iam_policy_attachment" "transcribe_lambda_execution" {
  name       = "AWSLambdaBasicExecutionRole"
  roles      = ["${aws_iam_role.lambda.name}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "stop_instance" {
  name        = "${var.lambda_name}-stop-instance"
  path        = "/"
  description = "Allow ${var.lambda_name} to stop ${aws_instance.bastion.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:StopInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "stop_instance" {
  name       = "${var.lambda_name}-stop-instance"
  roles      = ["${aws_iam_role.lambda.name}"]
  policy_arn = aws_iam_policy.stop_instance.arn
}

resource "aws_sns_topic" "ssh_logins" {
  name = var.lambda_name
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.ssh_logins.arn
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
  source_arn    = aws_sns_topic.ssh_logins.arn
}

resource "aws_cloudwatch_log_metric_filter" "invalid_logins" {
  name           = var.lambda_name
  pattern        = "[Mon, day, timestamp, ip, id, status = Invalid*]"
  log_group_name = "/var/log/secure"

  metric_transformation {
    name      = "InvalidSSHLogin"
    namespace = "SSH"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "invalid_logins" {
  alarm_name          = var.lambda_name
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "InvalidSSHLogin"
  namespace           = "SSH"
  period              = "120"
  statistic           = "Average"
  threshold           = "3"
  alarm_description   = "Trigger ${var.lambda_name} on three invalid SSH attempts ${aws_instance.bastion.id}"
  alarm_actions       = [aws_sns_topic.ssh_logins.arn]
}
