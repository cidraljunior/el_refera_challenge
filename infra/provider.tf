terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = local.region
}

data "aws_caller_identity" "current" {}

locals {
  region = "us-east-1"
  account_id = data.aws_caller_identity.current.account_id
}