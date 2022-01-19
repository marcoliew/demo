# --------------------------------------------------------------------------------------------------
# Run bootstrap module (only) on new AWS Account twice - manually on same Server/Computer
# 1. Without terraform section (backend) in provider.tf
# 2. With backend section enabled.
# This will setup the S3 bucket and DynamoDB on First execution, 
# and second execution will push the tfstate file to S3 bucket.
# ---------------------------------------------------------------------------------------------------

locals {
  resource_prefix = lower("${var.lhd}-${var.environment}-${var.app}")
 
}

data "terraform_remote_state" "dependencies" {
  backend = "s3"
  config = {
    bucket = "${var.environment}-dependencies-app1-tfstate-bucket"
    key    = "${var.environment}/dependencies/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

data "aws_security_groups" "smc_provided_sg_ids" {
  tags = {
    Name = "AP2-INF-PROVIDER-SG-Provider-Services*"
  }
}

data "aws_ssm_parameter" "logging_bucket" {
  name = "/${var.lhd}/${var.environment}/${var.app}/logging_bucket"
  depends_on = [module.bootstrap]
}
# ---------------------------------------------------------------------------------------------------
# Terraform provider and backend configuration
# ---------------------------------------------------------------------------------------------------

terraform {

  required_version = ">=0.12.16"

  backend "s3" {}
}

provider "aws" {
  region = "ap-southeast-2"
}

module "bootstrap" {
  source               = "../../Modules/bootstrap"
  s3_tfstate_bucket    = var.s3_tfstate_bucket
  dynamo_db_table_name = var.dynamo_db_table_name
  env                  = var.environment
  account_id           = var.account_id
  envtag               = var.envtag
  lhd                  = var.lhd
  artifacts_bucket     = var.artifacts_bucket
}
data "aws_ssm_parameter" "githealth_pat" {
  name = var.github_pat
}

# ----------------------------------------------------------------------------------------------------
# Create a Codebuild project as Git webhook, Name: ${var.codebuildenv}-${var.github_repository_name} (poc-app1), 
# ----------------------------------------------------------------------------------------------------

module "hook" {
  source                 = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-codebuild-githealth.git?ref=v1.0.2"
  github_access_token    = data.aws_ssm_parameter.githealth_pat.value
  github_repository_name = var.app
  github_repository_url  = "https://git.health.nsw.gov.au/ehnsw-clinicalapps/app1.git"
  github_organization    = "ehnsw-clinicalapps"
  webhook_filter         = "FILE_PATH"
  webhook_filter_pattern = ""
  webhook_filter_branch  = var.webhook_filter_branch       
  codebuildenv           = "${var.lhd}-${var.environment}"
  custom_image           = true
  custom_image_buildspec = "AppDeployment/buildspecs/gitwebhook_buildspec.yml"
}

data "aws_arn" "github_hook_bucket" {
  arn = module.hook.artifact_bucket_arn
}


# app1-appdeployment-pipeline, 1-validate_plan-app1-appdeployment, 2-apply-app1-appdeployment
module "AppPipeline" {
  source = "../../Modules/Pipeline"
  #role                     = "AppDeployment" #var.environment
  deployment_role          = "AppDeployment"
  type                     = "AppDeployment"
  account_id               = var.account_id
  source_s3_bucket         = data.aws_arn.github_hook_bucket.resource
  environment              = var.environment
  lhd                      = var.lhd
  app                      = var.app
  build_timeout            = 90
  codebuild_security_group = data.terraform_remote_state.dependencies.outputs.security_group_packer
  logging_bucket = data.aws_ssm_parameter.logging_bucket.value
  #poll_changes = "false"
}

# # ----------------------------------------------------------------------------------------------------
# # Placeholder for IAM
# # ----------------------------------------------------------------------------------------------------

# # ----------------------------------------------------------------------------------------------------
# # Placeholder for EC2 Stack
# # ----------------------------------------------------------------------------------------------------

module "EC2_Web_Stack" {
  source                    = "../../Modules/EC2_Stack"
  app                       = var.app
  environment               = var.environment
  instancerole              = "web"
  lhd                       = var.lhd
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  desired_size              = var.asg_desired_size
  health_check_grace_period = var.asg_check_period
  health_check_type         = var.asg_check_type
  instance_type             = var.asg_instance_type
  force_delete              = var.asg_force_delete
  termination_policies      = var.asg_termination_policies
  timeouts                  = var.asg_timeouts
  vpc_id                    = var.vpc_id
  #key_name                  = data.terraform_remote_state.dependencies.outputs.default-kp-ec2
  userdata_filename         = "userdata_web"
  lb_healthcheck_path       = "/titanium/web/admin/configuration.html"
  eH_std_tags               = var.eH_std_tags
  nlb_subnet_mapping        = var.nlb_subnet_mapping
  elb_logging_bucket        = data.aws_ssm_parameter.logging_bucket.value
  esb_port                  = var.esb_port

  

  # Shareable resources
  alb_security_groups = data.terraform_remote_state.dependencies.outputs.security_group_alb
  ec2_security_groups = data.terraform_remote_state.dependencies.outputs.security_group_ec2
  ec2_instance_role   = data.terraform_remote_state.dependencies.outputs.ec2_profile_name
  subnet_list         = var.vpc_subnets

  # Event resources
  ssm_doc_asg_lifecycle_role_arn     = data.terraform_remote_state.dependencies.outputs.ssm_doc_asg_lifecycle_role_arn
  event_run_ssm_doc_role_arn         = data.terraform_remote_state.dependencies.outputs.event_run_ssm_doc_role_arn
  sns_topic_default_notification_arn = data.terraform_remote_state.dependencies.outputs.sns_topic_default_notification_arn
  asg_hook_sns_role_arn              = data.terraform_remote_state.dependencies.outputs.asg_hook_sns_role_arn
}

