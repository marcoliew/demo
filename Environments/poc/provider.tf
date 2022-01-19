terraform {

  required_version = ">=0.12.16"

  backend "s3" {
    encrypt        = true
    bucket         = "poc-app1-tfstate-test-bucket"
    dynamodb_table = "poc-app1-test-lockDynamo"
    key            = "poc/terraform.tfstate"
    region         = "ap-southeast-2"
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

