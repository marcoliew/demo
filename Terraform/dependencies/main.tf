# --------------------------------------------------------------------------------------------------
# Run bootstrap module (only) on new AWS Account twice - manually on same Server/Computer
# 1. Without terraform section (backend) in provider.tf
# 2. With backend section enabled.
# This will setup the S3 bucket and DynamoDB on First execution, 
# and second execution will push the tfstate file to S3 bucket.
# ---------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------
# Terraform provider and backend configuration
# ---------------------------------------------------------------------------------------------------

locals {
  resource_prefix = lower("${var.lhd}-${var.environment}-${var.app}")
  #alb_security_ids = concat([module.security_group_Alb.security_group_id], tolist(data.aws_security_groups.smc_provided_sg_ids.ids))
  ssrs_security_ids = concat([module.security_group_ssrs.security_group_id], tolist(data.aws_security_groups.smc_provided_sg_ids.ids))
  fsx_security_ids   = concat([module.security_group_Fsx.security_group_id], tolist(data.aws_security_groups.smc_provided_sg_ids.ids))
  rds_security_ids = concat([module.security_group_RDS.security_group_id], tolist(data.aws_security_groups.smc_provided_sg_ids.ids))
  fsx_creds          = jsondecode(data.aws_secretsmanager_secret_version.fsxcred.secret_string)
}

data "aws_security_groups" "smc_provided_sg_ids" {
  tags = {
    Name = "AP2-INF-PROVIDER-SG-Provider-Services*"
  }
}
data "aws_secretsmanager_secret_version" "fsxcred" {
  secret_id = var.fsx_secret_id
}

data "aws_ssm_parameter" "logging_bucket" {
  name = "/${var.lhd}/${var.environment}/${var.app}/logging_bucket"
  depends_on = [module.bootstrap]
}
 data "aws_kms_key" "rds_alias" {
  key_id = var.kms_key_name
}


data "aws_ssm_parameter" "githealth_pat" {
  name = var.github_pat
}

data "aws_ec2_managed_prefix_list" "jumphosts" {
  name = "AP2-INF-PROVIDER-Cloud-JumpHosts"
}

data "aws_ssm_parameter" "infra_proxy" {
  name = "/Cloud/InfrastructureProxy/PrefixListId"
}
data "aws_ec2_managed_prefix_list" "tenable" {
  name = "AP2-INF-PROVIDER-Cloud-Tenable"
}

data "aws_ec2_managed_prefix_list" "aws_endpoints" {
  name = "AP2-INF-PROVIDER-Cloud-Endpoints"
}

data "aws_ec2_managed_prefix_list" "s3_endpoint" {
  name = "com.amazonaws.ap-southeast-2.s3"
}


data "aws_arn" "github_hook_bucket" {
  arn = module.hook.artifact_bucket_arn
}

resource "aws_ec2_managed_prefix_list" "citrix-smc" {
  name           = "citrix-smc-cidr"
  address_family = "IPv4"
  max_entries    = 4

  entry {
    cidr        = "10.104.64.0/20"
    description = "citrix subnet 1"
  }
  entry {
    cidr        = "10.104.80.0/20"
    description = "citrix subnet 2"
  }
  entry {
    cidr        = "10.104.96.0/20"
    description = "citrix subnet 3"
  }
  entry {
    cidr        = "10.104.112.0/20"
    description = "citrix subnet 4"
  }

}


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
  artifacts_bucket     = var.artifacts_bucket
  env                  = var.environment
  account_id           = var.account_id
  envtag               = var.envtag
  lhd                  = var.lhd
}

resource "aws_s3_bucket" "app1_sqlbackup" {
  bucket = "${local.resource_prefix}-sqlnativebackup"
  acl    = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        # kms_master_key_id = var.kms_master_key_id
        sse_algorithm = "AES256"
      }
    }
  }
  tags = var.eH_std_tags
}

resource "aws_s3_bucket_public_access_block" "app1_sqlbackup" {
  bucket = aws_s3_bucket.app1_sqlbackup.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "user-data" {
  bucket = "${local.resource_prefix}-userdata"
  acl = "private"
}

resource "aws_s3_bucket_object" "user-data-web" {
  bucket = aws_s3_bucket.user-data.id
  key    = "userdata_web.ps1"
  source = "../../APP1scripts/userdata_web.ps1"
  etag   = filemd5("../../APP1scripts/userdata_web.ps1")
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
  webhook_filter         = "EVENT" #"FILE_PATH"
  webhook_filter_pattern = "PUSH"  #"/Environments"
  webhook_filter_branch  = var.webhook_filter_branch
  codebuildenv           = "${var.lhd}-${var.environment}" #"${local.resource_prefix}"
  custom_image           = true
  custom_image_buildspec = "AppDeployment/buildspecs/gitwebhook_buildspec.yml"
}


# ----------------------------------------------------------------------------------------------------
# Code Pipelines for Terraform and AMI Bakeries
# ----------------------------------------------------------------------------------------------------

module "AppPipeline" {
  source                   = "../../Modules/Pipeline"
  type                     = "AppDeployment"
  deployment_role          = "dependencies"
  account_id               = var.account_id
  source_s3_bucket         = data.aws_arn.github_hook_bucket.resource
  environment              = var.environment
  lhd                      = var.lhd
  app                      = var.app
  build_timeout            = 90
  codebuild_security_group = module.security_group_packer.security_group_id
  logging_bucket = data.aws_ssm_parameter.logging_bucket.value
}

# app1-amibakery-pipeline, Packer_build-app1-amibakery
module "AMIBakeryPipeline" {
  source                   = "../../Modules/VPCPipeline"
  type                     = "AMIBakery"
  deployment_role          = "CitrixAMI"
  account_id               = var.account_id
  source_s3_bucket         = data.aws_arn.github_hook_bucket.resource
  environment              = var.environment
  lhd                      = var.lhd
  app                      = var.app
  build_timeout            = 120
  codebuild_security_group = module.security_group_packer.security_group_id
  poll_changes             = "false"
  vpc_subnets              = var.vpc_subnets
  logging_bucket = data.aws_ssm_parameter.logging_bucket.value
  vpc_id                   = var.vpc_id
}

module "AMIBakeryPipeline_Web" {
  source                   = "../../Modules/VPCPipeline"
  type                     = "AMIBakery"
  deployment_role          = "WebAMI"
  account_id               = var.account_id
  source_s3_bucket         = data.aws_arn.github_hook_bucket.resource
  environment              = var.environment
  lhd                      = var.lhd
  app                      = var.app
  build_timeout            = 120
  codebuild_security_group = module.security_group_packer.security_group_id
  poll_changes             = "false"
  vpc_subnets              = var.vpc_subnets
  logging_bucket = data.aws_ssm_parameter.logging_bucket.value
  vpc_id                   = var.vpc_id
}

# ssrs-amibakery
module "SSRSAMIBakeryPipeline" {
  source                   = "../../Modules/VPCPipeline"
  type                     = "AMIBakery"
  deployment_role          = "SSRSAMI"
  account_id               = var.account_id
  source_s3_bucket         = data.aws_arn.github_hook_bucket.resource
  environment              = var.environment
  lhd                      = var.lhd
  app                      = var.app
  build_timeout            = 120
  codebuild_security_group = module.security_group_packer.security_group_id
  poll_changes             = "false"
  vpc_subnets              = var.vpc_subnets
  logging_bucket = data.aws_ssm_parameter.logging_bucket.value
  vpc_id                   = var.vpc_id
}

module "fsx" {
  source                          = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-fsx-windows-file-system-selfmanaged-ad.git?ref=v2.4.0"
  name_tag                        = "${local.resource_prefix}-Fsx"
  environment_tag                 = var.environment
  deployment_type                 = var.fsx_deployment_type
  storage_type                    = var.fsx_storage_type
  security_group_ids              = local.fsx_security_ids
  storage_capacity                = var.fsx_storage_capacity
  subnet_ids                      = var.fsx_subnets
  throughput_capacity             = var.fsx_throughput_capacity
  skip_final_backup               = true
  automatic_backup_retention_days = 0
  preferred_subnet_id               = var.vpc_subnet1
  dns_ips                           = var.fsx_dns_ips
  domain_name                       = var.fsx_domain_name
  domain_join_username              = local.fsx_creds.admuser
  domain_join_password              = local.fsx_creds.admpwd
  ad_ou                             = "OU=Servers,${local.fsx_creds.ou}"
  fsx_admins_group                  = local.fsx_creds.domaingroup
  #aliases = var.fsx_alias
  file_access_audit_log_level       = "SUCCESS_AND_FAILURE"
  file_share_access_audit_log_level = "SUCCESS_AND_FAILURE"
  audit_log_destination             = aws_cloudwatch_log_group.fsx_shared1_log_group.arn
  optional_tags                     = merge({ "backup-plan" = "fsx" },var.eH_std_tags)
}


# FSX backup plan

module "fsx_backup_plan" {
  source            = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-backup-config.git?ref=v1.1.0"
  environment_tag   = var.environment
  vault_name_prefix = var.fsx_backup_vault_name_prefix
  enabled           = var.fsx_backup_enabled

  rules = [
    {
      name              = "fsx-daily-backup-rule"
      schedule          = var.fsx_backup_daily_schedule
      target_vault_name = null # Set to null so it will use the one created as part of this module
      start_window      = var.fsx_backup_start_window
      completion_window = var.fsx_backup_completion_window
      lifecycle = {
        cold_storage_after = 0
        delete_after       = var.fsx_backup_daily_retention
      }
      recovery_point_tags = merge({ BackupType = "daily" }, var.eH_std_tags)
    },
    {
      name              = "fsx-weekly-backup-rule"
      schedule          = var.fsx_backup_weekly_schedule
      target_vault_name = null # Set to null so it will use the one created as part of this module
      start_window      = var.fsx_backup_start_window
      completion_window = var.fsx_backup_completion_window
      lifecycle = {
        cold_storage_after = 0
        delete_after       = var.fsx_backup_weekly_retention
      }
      recovery_point_tags = merge({ BackupType = "weekly" }, var.eH_std_tags)
    },
    {
      name              = "fsx-monthly-backup-rule"
      schedule          = var.fsx_backup_monthly_schedule
      target_vault_name = null # Set to null so it will use the one created as part of this module
      start_window      = var.fsx_backup_start_window
      completion_window = var.fsx_backup_completion_window
      lifecycle = {
        cold_storage_after = 0
        delete_after       = var.fsx_backup_monthly_retention
      }
      recovery_point_tags = merge({ BackupType = "monthly" }, var.eH_std_tags)
    },
  ]
  # Multiple selections
  # Daily, Weekly, Monthly and Yearly Backups and retention
  selections = [
    {
      name = "fsx_backup_selection"
      selection_tag = {
        type  = "STRINGEQUALS"
        key   = "backup-plan"
        value = "fsx"
      }
    },
  ]
  optional_tags = var.eH_std_tags
}


resource "aws_cloudwatch_log_group" "fsx_shared1_log_group" {
  name              = join("", ["/aws/fsx/"], ["${var.environment}"])
  retention_in_days = 0
  tags              = var.eH_std_tags
}


# # ----------------------------------------------------------------------------------------------------
# # Create default key pair for ec2 across LHDs
# # ----------------------------------------------------------------------------------------------------

resource "tls_private_key" "default-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#resource "aws_key_pair" "default-kp-ec2" {
#  key_name   = "default-kp-ec2"
#  public_key = tls_private_key.default-key.public_key_openssh
#}

resource "aws_ssm_parameter" "default-private-key" {
  name  = "/${local.resource_prefix}/keypair/private-key/default"
  type  = "String"
  value = tls_private_key.default-key.private_key_pem
}

# # ----------------------------------------------------------------------------------------------------
# # Create IAM Roles
# # ----------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------
#  SNS and Event
# ---------------------------------------------------------------------------------------------------

#SNS part
resource "aws_sns_topic" "DefaultNotificationTopic" {
  name = "${local.resource_prefix}-Default-Notify"
}

resource "aws_sns_topic_subscription" "DefaultTopicSubs-Email" {
  topic_arn = aws_sns_topic.DefaultNotificationTopic.arn
  protocol  = "email"
  endpoint  = "marco.w.liew@gmail.com"
}

resource "aws_sns_topic_subscription" "DefaultTopicSubs-SMS" {
  topic_arn = aws_sns_topic.DefaultNotificationTopic.arn
  protocol  = "sms"
  endpoint  = "+610451050619"
}

resource "aws_sns_topic_policy" "DefaultNotificationTopicPolicy" {
  arn = aws_sns_topic.DefaultNotificationTopic.arn

  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" = [
      {
        "Action" : "sns:Publish",
        "Resource" : aws_sns_topic.DefaultNotificationTopic.arn,
        "Principal" = {
          "Service" = "events.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : "My-statement-id"
      }
    ]

  })

}

# CW Event part
# Rule for latest app1 web AMI id update from parameter /poc/web/amiid/latest

resource "aws_cloudwatch_event_rule" "WebAMIUpdateEvent" {
  name        = "${local.resource_prefix}-WebAMIUpdateEvent"
  description = "This will be trigger when a new app1 Web AMI image created and the /${local.resource_prefix}/web/amiid/latest parameter updated successfully."

  event_pattern = <<EOF
    {
        "source": [
        "aws.ssm"
        ],
        "detail-type": [
          "Parameter Store Change"
        ],
        "detail": {
          "name": [
          "/${var.environment}/${var.app}/${var.lhd}/web/amiid/latest"
        ],
        "operation": [
          "Update"
        ]
      }
    }
    EOF

}

resource "aws_cloudwatch_event_target" "sns-update" {
  rule = aws_cloudwatch_event_rule.WebAMIUpdateEvent.name
  #target_id = "${var.environment}-${var.appname}-NewAMI-Notify"
  arn = aws_sns_topic.DefaultNotificationTopic.arn
  input_transformer {
    input_paths = {
      resources = "$.resources",
      name      = "$.detail.name"
    }
    input_template = "\" A new Web Server AMI is generated and parameter store has been updated. Details: <resources> . \""
  }
}

# Rule for web AMI fail event
resource "aws_cloudwatch_event_rule" "WebAMIFailEvent" {
  name        = "${local.resource_prefix}-WebAMIFailEvent"
  description = "This will be trigger when codepipeline failed to create new AMI image in a transaction."

  event_pattern = <<EOF
  {
    "detail-type": [
      "AmiBuilder"
    ],
    "source": [
      "${var.app}.ami.codebuild"
    ],
    "detail": {
      "AmiStatus": [
        "Failed"
      ]
    }
  }
  EOF

}

resource "aws_cloudwatch_event_target" "sns-fail" {
  rule = aws_cloudwatch_event_rule.WebAMIFailEvent.name
  #target_id = "${var.environment}-${var.appname}-NewAMI-Notify"
  arn = aws_sns_topic.DefaultNotificationTopic.arn
  input_transformer {
    /*     input_paths = {
      resources = "$.resources",
      name      = "$.detail.name"
    } */
    input_template = "\" An AMI failed transaction has occurred, please find check details from console. \""
  }
}

# Rule for web AMI succeeded event
resource "aws_cloudwatch_event_rule" "WebAMISucceedEvent" {
  name        = "${local.resource_prefix}-WebAMISucceedEvent"
  description = "This will be trigger when codepipeline succeeded to create new AMI image in a transaction."

  event_pattern = <<EOF
  {
    "detail-type": [
      "AmiBuilder"
    ],
    "source": [
      "${var.app}.ami.codebuild"
    ],
    "detail": {
      "AmiStatus": [
        "Created"
      ]
    }
  }
  EOF

}

resource "aws_cloudwatch_event_target" "sns-succeed" {
  rule = aws_cloudwatch_event_rule.WebAMISucceedEvent.name
  #target_id = "${var.environment}-${var.appname}-NewAMI-Notify"
  arn = aws_sns_topic.DefaultNotificationTopic.arn
  input_transformer {
    input_paths = {
      resources = "$.resources"
    }
    input_template = "\" New Web Server AMI has been created: <resources>. \""
  }
}

# ----------------------------------------------------------------------------------------------------
# Placeholder for SSRS Server Configuration
# ----------------------------------------------------------------------------------------------------
data "aws_ami" "ssrs" {
   most_recent = true
   owners      = ["self"]
   filter {
     name   = "virtualization-type"
     values = ["hvm"]
   }
   filter {
     name   = "root-device-type"
     values = ["ebs"]
   }
   filter {
    name   = "state"
    values = ["available"]
  }
   filter {
     name   = "name"
     values = ["app1-ssrs-AMI-*"]
   }

 }

 resource "aws_instance" "APP1ssrs" {
   ami                         = data.aws_ami.ssrs.id
   instance_type               = var.app_instance_type
   subnet_id                   = var.vpc_subnet1
   vpc_security_group_ids      = local.ssrs_security_ids
   user_data                   = base64encode(file("../../APP1scripts/ssrs_config.ps1"))
   associate_public_ip_address = false
   monitoring                  = false
   #key_name                    = "default-kp-ec2"
   #instance_initiated_shutdown_behavior = ""
   iam_instance_profile = "${local.resource_prefix}-ec2-profile"
 lifecycle {
    ignore_changes = [user_data,tags,key_name]
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = "100"
    delete_on_termination = false
    encrypted             = true
  }

   tags = merge(var.eH_std_tags,
 
     {
       environment = var.environment
     },
     {
       app = var.app
     }
   )
 }
 resource "aws_ebs_volume" "SSRS_D" {
   availability_zone = "ap-southeast-2a"
   size              = 300
 }
 resource "aws_volume_attachment" "ebs_att_D" {
   device_name = "/dev/sdh"
   volume_id   = aws_ebs_volume.SSRS_D.id
  instance_id = aws_instance.APP1ssrs.id
 }
 resource "aws_ebs_volume" "SSRS_E" {
   availability_zone = "ap-southeast-2a"
   size              = 100
 }
 resource "aws_volume_attachment" "ebs_att_E" {
   device_name = "/dev/sdi"
   volume_id   = aws_ebs_volume.SSRS_E.id
  instance_id = aws_instance.APP1ssrs.id
 }
 resource "aws_ebs_volume" "SSRS_F" {
   availability_zone = "ap-southeast-2a"
   size              = 300
 }
 resource "aws_volume_attachment" "ebs_att_F" {
   device_name = "/dev/sdj"
   volume_id   = aws_ebs_volume.SSRS_F.id
  instance_id = aws_instance.APP1ssrs.id
 }


resource "aws_kms_key" "this" {
  description              = var.kms_description
  customer_master_key_spec = var.key_spec
  is_enabled               = var.kms_enabled
  enable_key_rotation      = var.kms_rotation_enabled
  tags                     = var.eH_std_tags
  policy                   = data.aws_iam_policy_document.ebs_cmk_access.json
  depends_on               = [aws_iam_role.ec2_app1_role] #, aws_iam_service_linked_role.ec2autoscaling]
}

# Add an alias to the key
resource "aws_kms_alias" "this" {
  name          = "alias/${local.resource_prefix}"
  target_key_id = aws_kms_key.this.key_id
}



data "aws_iam_policy_document" "ebs_cmk_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }
    effect  = "Allow"
    actions = ["kms:*"]
    resources = [
      "*"
    ]
  }
  statement {

    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [
      "*"
    ]
  }
  statement {

    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
    }
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]

    resources = [
      "*"
    ]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values = [
        "true"
      ]
    }
  }
  statement {

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.account_id}:role/${local.resource_prefix}-ec2-role", 
      ]
    }
    effect = "Allow"
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [
      "*"
    ]
  }

  statement {

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.citrix_smc_account}:root",
      ]
    }
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:RevokeGrant"
    ]
    resources = [
      "*"
    ]
  }
}


resource "aws_ssm_parameter" "cw_agent_config" {
  description = "Cloudwatch agent config to configure custom log"
  name        = "/${local.resource_prefix}/cw_agent_config"
  type        = "String"
  value       = file("../../APP1scripts/cw_agent_config.txt")
}



resource "aws_secretsmanager_secret" "adcred" {
   name                    = "/${local.resource_prefix}/adcred"
   description             = "Active Directory details for domain join code"
   recovery_window_in_days = 0
   tags                    = var.eH_std_tags

}
