variable "environment" {
  description = "Environment"

}
variable "envtag" {
  description = "Environment name"

  validation {
    condition     = var.envtag == "poc" || var.envtag == "nonp" || var.envtag == "prod"
    error_message = "Error - envtag only accepts poc, nonp or prod."
  }
}

variable "lhd" {
  description = "Name of LHD"
}

variable "eH_std_tags" {
  type        = map(string)
  description = "eHealth Std Tags for each resource"
}

variable "s3_tfstate_bucket" {
  type        = string
  description = "S3 bucket name for Terraform state"
}
variable "dynamo_db_table_name" {
  type        = string
  description = "DynamoDB table name to hold Terraform lock"
}
variable "account_id" {
  type        = string
  description = "AWS Account ID"
}
variable "github_pat" {
  type        = string
  description = "SSM Parameter name for Personal access token (Githealth integration)"
}
variable "git_source_code_bucket" {
  description = "S3 Bucket name for storing Git code"
}
variable "vpc_id" {
  type        = string
  description = "AWS VPC ID"
}
variable "vpc_subnet1" {
  type = string
}
variable "vpc_subnet2" {
  type = string
}
variable "vpc_subnet3" {
  type = string
}
variable "vpc_subnets" {
  type = list(string)
}

variable "subnets_cidr" {
  type        = list(string)
  description = "List of Subnet ID's where resources to be created"
}

variable "s3_buckets_list" {
  type        = list(string)
  description = "List of S3 buckets to be created"
}
variable "iam_policy_arn" {
  description = "IAM Policy to be attached to EC2 role"
  type        = list(string)
}

variable "app" {
  type        = string
  description = "Applicatio name"
}

variable "webhook_filter_branch" {
  type        = string
  description = "Branch where all the latest codes will be pushed"
}

variable "asg_max_size" {
  type        = number
  description = ""
}

variable "asg_min_size" {
  description = ""
  type        = number
}

variable "asg_desired_size" {
  description = ""
  type        = number
}

variable "asg_check_period" {
  description = ""
  default     = "300"
  type        = number
}


variable "asg_check_type" {
  default     = "EC2"
  description = ""
  type        = string
}

variable "asg_instance_type" {
  type        = string
  description = "EC2 instance type for ASG"
}

variable "asg_timeouts" {
  #default = "15m"
  description = ""
  type        = string
}

variable "asg_force_delete" {
  default     = true
  description = ""
  type        = bool
}

variable "asg_termination_policies" {

  description = ""
  type        = list(string)
}

variable "artifacts_bucket" {
  type        = string
  description = "The S3 bucket for input artifacts."
  default     = null
}

variable "nlb_subnet_mapping" {}

variable "esb_port" {}