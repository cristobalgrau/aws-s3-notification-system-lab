# S3 File upload Notification System in AWS

## Overview

Infrastructure system designed to monitor the seamless uploading of files to an S3 Bucket. The system will trigger a Lambda Function to initiate the processing of the uploaded files:

1. The Lambda will generate and dispatch email notifications utilizing an SNS topic. 
2. The Lambda will store essential metadata related to the processed files in an SQS queue, for subsequent processing tasks. 

## Architecture Diagram

![image](https://github.com/cristobalgrau/aws-s3-notification-system-lab/assets/119089907/5436c964-4277-44ac-8316-d7ce9c6f8721)

## Services Used

| AWS Service | Name |
| ------------| ------ |
|S3 Bucket | notification-system-project |
| SNS | notification-system-topic |
| SQS | notification-system-sqs |
| Lambda | notification-system-lambda |
