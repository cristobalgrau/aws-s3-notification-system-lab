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

## Technology Stack

The project leverages a combination of tools and technologies to achieve its goals. The key technologies used include:

<p align="center"> <a href="https://aws.amazon.com" target="_blank" rel="noreferrer"> <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/9/93/Amazon_Web_Services_Logo.svg/2560px-Amazon_Web_Services_Logo.svg.png" alt="aws" width="80"/> </a> <a href="https://www.terraform.io/" target="_blank" rel="noreferrer"> <img src="https://www.datocms-assets.com/2885/1620155116-brandhcterraformverticalcolor.svg" alt="terraform" width="80"/> </a> <a href="https://www.python.org/" target="_blank" rel="noreferrer"> <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Python-logo-notext.svg/1869px-Python-logo-notext.svg.png" alt="python" width="70"/> </a></p>

- **AWS Console**: Used for manual setup and configuration of AWS resources.
- **Terraform**: Employed for Infrastructure as Code (IaC) to provision and manage AWS resources.
- **Python**: Utilized for scripting the code for the Lambda Function.

## Budget

The services used in this project are under the free tier

## Lab Deployment

### 1. S3 Bucket

First, you have to create the S3 Bucket assigning the name and leaving the default settings. Remember the naming rules for the bucket.

![image](https://github.com/cristobalgrau/aws-s3-notification-system-lab/assets/119089907/5942f351-81b4-49fc-93bd-02bbc7e45947)


### 2. Simple Notification Service (SNS)

Then, we have to create the SNS Topic and make the subscription for the email that will receive the notifications. 

In this case, for the SNS Topic creation, we will use STANDARD Type, because in this project we only have one lambda function triggering the SNS so we don't need to keep the ordering of the messages as the FIFO type offers. Assign the name for the Topic and leave the remaining options as default.

After creating the SNS Topic we need to create the SNS Subscription in the "Subscription Tab". Choose the email protocol and provide the email address for the subscription.

![image](https://github.com/cristobalgrau/aws-s3-notification-system-lab/assets/119089907/f2a01eee-ab5e-44cc-9dda-bb5fd450afba)


### 3. Simple Queue Service (SQS)

Same as we did with the SNS, we will create the SQS by choosing the STANDARD Type, because we don't need to keep an order in the messaging delivery. Just assign a name for the SQS and leave the other options as default.

![image](https://github.com/cristobalgrau/aws-s3-notification-system-lab/assets/119089907/54d5e248-ea26-4949-bf7b-d0fdebe42c3a)


### 4. Lambda Function

Proceed to the Lambda service in your console and create a New Lambda Function from Scratch. In this lab, we will use a Python code, so we selected Python 3.12 in the Runtime.

![image](https://github.com/cristobalgrau/aws-s3-notification-system-lab/assets/119089907/ee560dc7-3b32-40cd-aaa3-496d6a51d07c)


After creating the Lambda Function we will add the permissions needed in the role that the Lambda function will use. Inside the Lambda Function created, in the configuration tab - Permissions section, enter to the Role name and add the policies: `AmazonSNSFullAccess` and `AmazonSQSFullAccess`

![image](https://github.com/cristobalgrau/aws-s3-notification-system-lab/assets/119089907/57fe7bf3-09c2-4e24-99ec-707e875d3ac3)


**Then let's add the following Python Code to the Lambda Function:**

```python
import json
import boto3
import os  # Lib to interact with the OS

s3_client = boto3.client('s3')
sns_client = boto3.client('sns')
sqs_client = boto3.client('sqs')


def lambda_handler(event, context):
    # Retrieve the SNS topic ARN and SQS queue URL from environment variables
    sns_topic_arn = os.environ['SNS_TOPIC_ARN']
    sqs_queue_url = os.environ['SQS_QUEUE_URL']

    # Process S3 event records
    for record in event['Records']:
        print(event)
        # Extract S3 bucket and object information
        s3_bucket = record['s3']['bucket']['name']
        s3_key = record['s3']['object']['key']
        
        # Sending metadata to SQS
        metadata = {
            'bucket': s3_bucket,
            'key': s3_key,
            'timestamp': record['eventTime']
        }
        
        sqs_response = sqs_client.send_message(
            QueueUrl=sqs_queue_url,
            MessageBody=json.dumps(metadata)
        )
        
        # Sending a notification to SNS
        notification_message = f"New file uploaded to S3 bucket '{s3_bucket}' with the key '{s3_key}'"
        
        sns_response = sns_client.publish(
            TopicArn=sns_topic_arn,
            Message=notification_message,
            Subject="File Upload Notification"
        )

    return {
        'statusCode': 200,
        'body': json.dumps('Done')
    }

```

In this Python code, we used the Environment Variables to avoid exposing sensitive information. AWS Lambda supports environment variables, and you can use them to store sensitive data or configuration that your code can access at runtime, in this way, any sensitive data is not hard-coded into your source files.

The way to use the Lambda Env Vars is with the following code snippet:

```python
import os

sns_topic_arn = os.environ['SNS_TOPIC_ARN']
sqs_queue_url = os.environ['SQS_QUEUE_URL']
```

Where `SNS_TOPIC_ARN` and `SQS_QUEUE_URL` are predefined in the Environment Variable section inside the Lambda Configuration Tab.

### 5. S3 Event notifications

In the S3 Bucket, we have to create the Event Notifications option to trigger our Lambda Function. You can set the specific event types you want to be triggering your lambda, which could be: creation, removal, restore, tagging, etc., and then choose the Lambda function that will be triggered.

S3 event notifications offer a flexible and scalable way to respond to changes in your S3 bucket without the need for continuous polling. This event-driven approach enhances automation, reduces latency, and enables scalable and efficient processing of data.

![image](https://github.com/cristobalgrau/aws-s3-notification-system-lab/assets/119089907/d622d27d-e03e-4bd3-ac36-d3c36ba37079)


## Lab Testing

Let's test our infrastructure.

If you have set everything good, after uploading a file in the S3 Bucket you will receive the following email notification from your SNS Topic:

![image](https://github.com/cristobalgrau/aws-s3-notification-system-lab/assets/119089907/73d23521-7e08-4d71-8a70-94ccb13a833b)

You should have your message in the SQS with the Metadata that was set in the previous steps

![image](https://github.com/cristobalgrau/aws-s3-notification-system-lab/assets/119089907/48a41050-8233-4a2f-a021-2664c659d778)

## Troubleshooting

If for any reason you are not receiving the notification you can use AWS CloudWatch to verify the logs and see what could be happening.

In the CloudWatch service look for `Log Groups` and inside you will see all the Lambdas you have. Select the Lambda you are using and then you will be able to see the `Log Streams`, one for each time the Lambda runs.

Here are some examples of errors I found in the Log:

**- OS Library was not installed in the lambda code to use the Env Vars**

![image](https://github.com/cristobalgrau/aws-s3-notification-system-lab/assets/119089907/516c87ff-c3d2-4fd1-8049-813996e32725)

**- Mistyping of ARN values in the Env Vars**

![image](https://github.com/cristobalgrau/aws-s3-notification-system-lab/assets/119089907/5b44c503-9413-4698-9a91-1ee3aebd5d0e)

**- The S3 Bucket was empty when I ran the Lambda for code testing**

![image](https://github.com/cristobalgrau/aws-s3-notification-system-lab/assets/119089907/2bd3d2e6-edac-4d91-8005-33088501e2b3)

## Clean Up

- Delete Lambda Function
- Delete SNS
- Delete SQS
- Empty and Delete S3 Bucket
- Delete IAM Role
