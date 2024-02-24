variable "aws-region" {
  description = "AWS Region to deploy the Infrastructure"
  type        = string
}

variable "bucket-name" {
  description = "Name for the S3 Bucket"
  type        = string
}

variable "sns-name" {
  description = "Name for SNS Topic"
  type        = string
}

variable "sns-email-sub" {
  description = "email for Notification in the SNS Topic Subscription"
  type        = string
}

variable "sqs-name" {
  description = "Name for SQS"
  type        = string
}

variable "lambda-name" {
  description = "Name for the Lambda Function used to trigger SNS and SQS"
  type        = string
}