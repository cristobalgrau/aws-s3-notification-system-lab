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

