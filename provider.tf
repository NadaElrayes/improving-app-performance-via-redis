terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.37.0"
    }
  }
}

provider "aws" {
  region  = "ap-southeast-1"
  profile = var.profile_name
  default_tags {
    tags = {
      project   = "challenge-1"
      Terraform = "true"
    }
  }
}