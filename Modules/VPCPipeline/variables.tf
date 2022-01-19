variable "account_id" {
  default = "497427545767"
}

variable "docker_build_image" {
  default = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
}
variable "logging_bucket" {}
variable "type" {
}

variable "app" {
}

variable "secondary_github_repository_url" {
  default = "https://git.health.nsw.gov.au/ehnsw-terraform/roadmap.git"
}
variable "vpc_id" {
  type        = string
  description = "AWS VPC ID"
}

variable "vpc_subnets" {
  type = list(string)
}
variable "build_timeout" {
  default = "40"
}

variable "poll_changes" {
  default = "true"
}

variable "source_s3_bucket" {
  description = "S3 Bucket used to store Git code"
}

variable "environment" {
  description = "Environment"
}

variable "lhd" {}

variable "deployment_role" {}

variable "codebuild_security_group" {}

variable "sse_algorithm" {
  type        = string
  description = "The server-side encryption algorithm to use. Valid values are AES256 and aws:kms"
  default     = "AES256"
}
