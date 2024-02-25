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

## Budget

The services used in this project are under the free tier

## Lab Deployment

### 1. S3 Bucket

First, you have to create the S3 Bucket assigning the name and leaving the default settings. Remember the naming rules for the bucket.

![image](https://github.com/cristobalgrau/aws-s3-notification-system-lab/assets/119089907/3c300dea-ab69-4d02-bf07-d1bb23759698)

### 2. Simple Notification Service (SNS)

Then, we have to create the SNS Topic and make the subscription for the email that will receive the notifications. 

In this case, for the SNS Topic creation, we will use STANDARD Type, because in this project we only have one lambda function triggering the SNS so we don't need to keep the ordering of the messages as the FIFO type offers. Assign the name for the Topic and leave the remaining options as default.

After creating the SNS Topic we need to create the SNS Subscription in the "Subscription Tab". Choose the email protocol and provide the email address for the subscription.


