
variable "s3_tfstate_bucket" {
  description = "Name of the S3 bucket used for Terraform state storage"
}

variable "artifacts_bucket" {
  type        = string
  description = "The S3 bucket for input artifacts."
}
variable "dynamo_db_table_name" {
  description = "Name of DynamoDB table used for Terraform locking"
}
variable "env" {
  description = "Environment Name"
}
variable "account_id" {
  description = "AWS Account ID"
}
variable "envtag" {
  description = "AWS SMC Environment"
}
variable "app" {
  default = "app1"
}

variable "lhd" {
  description = "Name of LHD"
}