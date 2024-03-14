# Automating S3 Notification System with Terraform: Infrastructure Development Lab

## Utilizing Gitpod Code Editor

For the development of this lab, Gitpod served as the primary tool for editing code. Gitpod stands out as an online Integrated Development Environment (IDE) that empowers developers to write, review, and manage their code directly within a web browser. Seamlessly integrating with Git repositories like GitHub, GitLab, and Bitbucket, Gitpod eliminates the need for setting up a local development environment, thereby streamlining the coding process.

The key reasons I used it for my lab are the following: 

- **Instant Setup**: With Gitpod, setting up a development environment is quick and easy. You can start coding immediately without spending time configuring a local machine with dependencies and tools.
- **Workspace Snapshots**: Gitpod automatically saves the state of a developer's workspace, including open files, terminal sessions, and installed dependencies. This allows you to pause the work and resume it later without losing any progress.
- **Cloud-based**: Since Gitpod runs entirely in the cloud, you can access the development environments from anywhere with an internet connection. This makes it convenient for remote work and from different PCs.
- **Integration with GitHub**: You can install a Chrome extension and from your GitHub repository launch your Workspace instantly.

## Setting up the Required Command Line Interfaces

To enhance modularity and facilitate reuse across various projects and labs, bash scripts were crafted for the installation of both the AWS CLI and Terraform CLI.

### AWS CLI

The installation script for the AWS CLI is encapsulated within the file named `install_aws_cli`.

```bash
#!/usr/bin/env bash

cd /workspace

rm -f '/workspace/awscliv2.zip'
rm -rf '/workspace/aws'

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

aws sts get-caller-identity

cd $PROJECT_ROOT
```

### Terraform CLI

Similarly, the installation script for the Terraform CLI resides within the file named `install_terraform_cli`.

```bash
#!/usr/bin/env bash

cd /workspace

sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl

wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update

sudo apt-get install terraform -y

cd $PROJECT_ROOT
```

### Configuring Environment Variables

Environment variables serve as crucial conduits for passing information between commands and subprocesses, streamlining various operations within your development environment.

**Env Commands**

- `env` used to list out all the Env Vars
- `env | grep EXAMPLE` It will filter the env vars and show all that have EXAMPLE on their name
- `export HELLO="world"` it will make this variable available for all child terminals until restart the workspace
- `unset HELLO` will erase the value of the variable
- `echo $HELLO` will print the env var value 

Every bash terminal window open will have its own env vars. If you want the env vars to persist to all future bash terminals you need to set env vars in your bash profile `.bash_profile`

**Persistent Env Vars in Gitpod**

In Gitpod, you can achieve the persistence of environment variables by storing them within Gitpod Secrets Storage using the following command:

```bash
gp env HELLO="world"
```

Subsequently, all forthcoming workspaces launched will automatically configure these environment variables for all bash terminals opened within those workspaces.

**Setting the ENV VARS needed**

```bash
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export PROJECT_ROOT="/workspace/aws-s3-notification-system-lab"

gp env AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
gp env AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
gp env PROJECT_ROOT="/workspace/aws-s3-notification-system-lab"
```

### Gitpod configuration to use the CLI installation scripts

To maintain organizational clarity and separation from the lab files, the bash scripts were housed within the `bin` directory.

To grant execution permissions to these scripts, the `chmod` command is employed as demonstrated below:

```bash
chmod u+x ./bin/install_aws_cli
```
```bash
chmod u+x ./bin/install_terraform_cli
```

Gitpod uses a file named `gitpod.yml` to configure various aspects of the development environment for a project. This YAML file defines the tools, dependencies, and tasks required to set up the workspace in Gitpod.

After make executable the scripts we can reference them from `gitpod.yml` file to install all that we need:

```bash
tasks:
  - name: aws-cli
    env:
      AWS_CLI_AUTO_PROMPT: on-partial
    before: |
      cd $PROJECT_ROOT
      source ./bin/install_aws_cli
      source ./bin/install_terraform_cli
      cd $PROJECT_ROOT

vscode:
  extensions:
    - amazonwebservices.aws-toolkit-vscode
    - hashicorp.terraform
    - phil294.git-log--graph
    - mhutchie.git-graph
```

## Lab Directory Structure

```
PROJECT_ROOT
│
├── bin/
│	├── install_aws_cli                  
│	└── install_terraform_cli            
├── lambda/
│	├── lambda_function.py              
│	└── lambda_function_payload.zip	   
├── main.tf                           
├── variables.tf            		      
├── terraform.tfvars        		      
├── env.needed            			      
├── README_terraform.md        		    
└── README.md               		      
```

This structured layout provides a clear delineation of project components, facilitating efficient organization and navigation within the development environment.


## Terraform development

To develop Infrastructure as Code (IaC) for AWS using Terraform, you can refer to the [Terraform Documentation for AWS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) for detailed guidance and reference.

The primary file for housing all Terraform code related to this lab is `main.tf`. Within this file, you will define the infrastructure components and configurations using Terraform's declarative syntax.


###  1. Terraform initial setup

To start our terraform code you need to set up the backend where will be located our terraform state file and specify the provider that will be used.  We specify Terraform version 1.6.6 at the minimum and the provider AWS version 5.31.0

```terraform
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
```

In this initialization phase, an Amazon S3 bucket named `terraform-state-grau` is designated as the backend to house the Terraform state file. It's important to note that for collaborative environments, it's recommended to utilize a DynamoDB database for state-locking mechanisms to prevent concurrent modifications.

Ensure to customize the backend configuration as per your requirements and adhere to best practices for managing Terraform state in a collaborative setting.


### 2. S3 Bucket creation

The following Terraform code facilitates the creation of an S3 bucket for the lab:

```terraform
resource "aws_s3_bucket" "project-bucket" {
  bucket = var.bucket-name
}
```
This snippet defines an AWS S3 bucket resource named `project-bucket`, utilizing a variable `var.bucket-name` to specify the desired bucket name. Ensure to adjust the variable `bucket-name` according to your project's naming conventions and requirements.

###  3. Simple Notification Service - SNS Creation

The following Terraform code facilitates the creation of an Amazon Simple Notification Service (SNS) topic along with a subscription for email notifications:

```terraform
resource "aws_sns_topic" "project_sns" {
  name = var.sns-name
}

resource "aws_sns_topic_subscription" "project_sns_target" {
  topic_arn = aws_sns_topic.project_sns.arn
  protocol  = "email"
  endpoint  = var.sns-email-sub
}
```
This code defines an SNS topic resource named `project_sns` with a name specified by the variable `var.sns-name`. Additionally, it creates an SNS topic subscription for email notifications, utilizing the specified email address stored in the variable `var.sns-email-sub`.

Ensure to customize the variables `sns-name` and `sns-email-sub` according to your project's naming conventions and requirements.

### 4. Simple Queue Service - SQS Creation

Similar to the creation of the SNS topic, the following Terraform code facilitates the creation of an Amazon Simple Queue Service (SQS) queue:

```terraform
resource "aws_sqs_queue" "project_sqs" {
  name                      = var.sqs-name
  delay_seconds             = 30
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 0
}
```
This code defines an SQS queue resource named `project_sqs`, specifying various attributes such as queue name (`sqs-name`), and the default values for the rest of the attributes.

Ensure to customize the variable `sqs-name` according to your project's naming conventions and requirements.


### 5. Lambda function Creation

For the Lambda function creation, Python is utilized as the programming language. The function leverages the Boto3 library for AWS resource manipulation and the OS library for interaction with environment variables, ensuring sensitive information is not exposed in the code. 

The Python code for the Lambda function is stored in the file named `lambda_function.py`, residing within the `lambda/` folder as depicted in the Lab Directory Structure tree. Below is the Python code for the Lambda function:

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

The Lambda function resource in Terraform needs your lambda function code in a ZIP file. To achieve this we used the Provider `Archive` to manipulate archive files and generate another file.

```terraform
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda/lambda_function_payload.zip"
}
```
In this way, we convert the lambda function in a ZIP file in the same folder `lambda/`

To create the Lambda Function resource it is needed a Role, so let's create the role with the following code:

```terraform
# Policy document for Lambda to Assume Role
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

# Creation of Role for Lambda Function
resource "aws_iam_role" "iam_for_lambda" {
  name               = "notification-system-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
```

After creating the role for lambda we need to attach the policies to manipulate SNS and SQS

```terraform
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
```

Now that we have the Lambda Role fully loaded with all policies needed it is time to create the Lambda Function

```terraform
resource "aws_lambda_function" "project_lambda" {
  filename      = "${path.module}/lambda/lambda_function_payload.zip"
  function_name = var.lambda-name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.12"

  # ENV VARS for Lambda
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.project_sns.arn
      SQS_QUEUE_URL = aws_sqs_queue.project_sqs.url
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.project_logs,
  ]
}
```
According to [Terraform lambda documentation for Cloudwatch logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function#cloudwatch-logging-and-permissions) it is required to create the `depends_on`. To comply with this required Logging and Cloudwatch resources we use the following code:

```terraform
# Creation of Cloudwatch Log Group
resource "aws_cloudwatch_log_group" "project_logs" {
  name              = "/aws/lambda/${var.lambda-name}"
  retention_in_days = 14
}

# Policy for Lambda Logging
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

# Attaching Lambda Logging Policy to the Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}
```

### 6. S3 Event Notification Creation

To trigger our lambda function we need to create the Event Notification on our S3 Bucket

Following the procedure on the [Terraform documentation for S3 Notification with Lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification#add-notification-configuration-to-lambda-function) we use the following code:

```terraform
data "aws_caller_identity" "current" {}

# Creation of S3 Bucket Event notification
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.project-bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.project_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

    depends_on = [aws_lambda_permission.allow_bucket]
}

# Adding Notification configuration to the Lambda Function
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.project_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.project-bucket.arn
  source_account = data.aws_caller_identity.current.account_id
}
```

In the previous code, the data source: `data "aws_caller_identity" "current" {}` is used to retrieve information about the AWS account identity that Terraform is currently using, such as the AWS account ID, ARN (Amazon Resource Name) of the caller identity, and the AWS principal ID (the unique identifier for the account or user making the request).
