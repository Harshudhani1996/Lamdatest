terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  region = "ap-south-1"  # Change to your desired AWS region
}

resource "aws_s3_bucket" "filesread" {
  bucket = "filesread"
}