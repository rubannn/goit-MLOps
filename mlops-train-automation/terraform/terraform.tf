terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "mlops-tfstate-goit-512523811086"
    key            = "mlops-train-automation/terraform.tfstate"
    region         = "us-east-1"
    profile        = "goit-terraform"
    dynamodb_table = "mlops-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}
