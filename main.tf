terraform {
  backend "s3" {
    bucket = "terraform-state-grau"
    key    = "sns_Lab/sns_infra"
    region = "us-east-1"
  }
  required_version = ">= 1.6.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0"
    }
  }
}

provider "aws" {
  region = var.aws-region

  # Setting default tag for all resources created in this IaC
  default_tags {
    tags = {
      Project = "Notification System"
    }
  }
}

# ==== STORAGE SECTION ====

resource "aws_s3_bucket" "project-bucket" {
  bucket = var.bucket-name
}

# ==== SNS Section ====

resource "aws_sns_topic" "project_sns" {
  name = var.sns-name
}

resource "aws_sns_topic_subscription" "project_sns_target" {
  topic_arn = aws_sns_topic.project_sns.arn
  protocol  = "email"
  endpoint  = var.sns-email-sub
}

# ==== SQS SECTION ====

resource "aws_sqs_queue" "project_sqs" {
  name                      = var.sqs-name
  delay_seconds             = 30
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 0
}

# ==== LAMBDA SECTION ====

# Creation of Lambda Function
resource "aws_lambda_function" "project_lambda" {
  filename      = "${path.module}/lambda/lambda_function_payload.zip"
  function_name = var.lambda-name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.12"
}

# Creation of Role for Lambda Function
resource "aws_iam_role" "iam_for_lambda" {
  name               = "notification-system-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Attaching the AmazonSNSFullAccess policy
resource "aws_iam_role_policy_attachment" "attach-sns-policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

# Attaching the AmazonSQSFullAccess policy
resource "aws_iam_role_policy_attachment" "attach-sqs-policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}


# ==== DATA SOURCE SECTION ====

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda/lambda_function_payload.zip"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}