# --------------------------------------------------------------------------------------------------
# Run bootstrap module (only) on new AWS Account twice - manually on same Server/Computer
# 1. Without terraform section (backend) in provider.tf
# 2. With backend section enabled.
# This will setup the S3 bucket and DynamoDB on First execution, 
# and second execution will push the tfstate file to S3 bucket.
# ---------------------------------------------------------------------------------------------------
/* 
module "bootstrap" {
  source               = "../../../Modules/bootstrap"
  s3_tfstate_bucket    = var.s3_tfstate_bucket
  dynamo_db_table_name = var.dynamo_db_table_name
  env                  = var.environment
  account_id           = var.account_id
  envtag               = var.envtag
  eH_std_tags          = var.eH_std_tags
}
 */
# ---------------------------------------------------------------------------------
# Create Global Resources such as S3 Buckets, DNS Private hosted zone, EFS etc.
#----------------------------------------------------------------------------------

# module "create_global_resources" {
#   source           = "../../../Modules/global"
#   env              = var.environment
#   envtag           = var.envtag
#   s3_buckets_names = var.s3_buckets_list
#   s3_iam_role_arn  = module.iam_roles.iam_role_arn
#   vpc_id           = var.vpc_id
# }


data "aws_ssm_parameter" "githealth_pat" {
  name = var.github_pat
}

# ----------------------------------------------------------------------------------------------------
# Create a Codebuild project as Git webhook, Name: ${var.codebuildenv}-${var.github_repository_name} (poc-app1), 
# ----------------------------------------------------------------------------------------------------

module "hook" {
  source                 = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-codebuild-githealth.git?ref=v1.0.1"
  github_access_token    = data.aws_ssm_parameter.githealth_pat.value
  github_repository_name = "app1"
  github_repository_url  = "https://git.health.nsw.gov.au/ehnsw-clinicalapps/app1.git"
  github_organization    = "ehnsw-clinicalapps"
  webhook_filter         = "FILE_PATH"
  webhook_filter_pattern = "Environments/${var.environment}/*"
  webhook_filter_branch  = var.webhook_filter_branch #"feature/newpipeline-Wei"
  codebuildenv           = "${var.environment}-${var.lhd}"
}

data "aws_arn" "github_hook_bucket" {
  arn = module.hook.artifact_bucket_arn
}


# app1-appdeployment-pipeline, 1-validate_plan-app1-appdeployment, 2-apply-app1-appdeployment
module "AppPipeline" {
  source                   = "../../../Modules/Pipeline"
  role                     = "AppDeployment" #var.environment
  deployment_role          = "AppDeployment"
  account_id               = var.account_id
  source_s3_bucket         = data.aws_arn.github_hook_bucket.resource
  environment              = var.environment
  appname                  = var.app
  build_timeout            = 90
  codebuild_security_group = module.security_group_packer.security_group_id
}

# app1-amibakery-pipeline, Packer_build-app1-amibakery
module "CitrixAMIBakeryPipeline" {
  source                   = "../../../Modules/Pipeline"
  role                     = "AMIBakery" #var.environment
  deployment_role          = "CitrixAMI"
  account_id               = var.account_id
  source_s3_bucket         = data.aws_arn.github_hook_bucket.resource
  environment              = var.environment
  appname                  = var.app
  build_timeout            = 120
  codebuild_security_group = module.security_group_packer.security_group_id
}

# ssrs-amibakery
module "SSRSAMIBakeryPipeline" {
  source                   = "../../../Modules/Pipeline"
  role                     = "AMIBakery" #var.environment
  deployment_role          = "SSRSAMI"
  account_id               = var.account_id
  source_s3_bucket         = data.aws_arn.github_hook_bucket.resource
  environment              = var.environment
  appname                  = var.app
  build_timeout            = 120
  codebuild_security_group = module.security_group_packer.security_group_id
}

# ---------------------------------------------------------------------------------
# Create IAM Roles
#----------------------------------------------------------------------------------


# module "iam_roles" {
#   source = "../../../Modules/iam"

# }

# ----------------------------------------------------------------------------------------------------
# Security Groups for various resources
# ----------------------------------------------------------------------------------------------------
module "security_group_packer" {
  source                   = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-security-group.git"
  environment_tag          = var.environment
  name                     = "${var.app}-${var.environment}-Packer-Codebuild"
  name_tag                 = "${var.app}-${var.environment}-Packer-Codebuild"
  description              = "Security Group To Allow Access To Packer builder for Creation of AMI"
  revoke_rules_on_delete   = false
  vpc_id                   = var.vpc_id
  ingress_rules_additional = var.ingress_rules_additional

  ingress_rules_base = [
    {
      description = "All traffic from VPC",
      from_port   = 0,
      to_port     = 0,
      protocol    = "all",
      cidr_blocks = ["10.0.0.0/8"]
    },
  ]
  egress_rules_base = [
    {
      description = "All traffic to anywhere",
      from_port   = 0,
      to_port     = 0,
      protocol    = "-1",
      cidr_blocks = ["0.0.0.0/0"]
    },
  ]

}

/* 
module "security_group_ec2_someservers" {
  source                   = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-security-group.git"
  environment_tag          = var.environment
  name_tag                 = "someservers-sg-name"
  description              = "Security Group To Allow Access To Some Servers In aproject-dev"
  revoke_rules_on_delete   = false
  vpc_id                   = var.vpc_id
  ingress_rules_additional = var.ingress_rules_additional
}


module "security_group_Fsx" {
  source                   = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-security-group.git"
  environment_tag          = var.environment
  name                     = "${var.app}-${var.environment}-Fsx-sg"
  name_tag                 = "${var.app}-${var.environment}-Fsx-sg"
  description              = "Security Group To Allow Access To Fsx share drive"
  revoke_rules_on_delete   = false
  vpc_id                   = var.vpc_id
  ingress_rules_additional = var.ingress_rules_additional

  ingress_rules_base = [ 
    {
      description = "All traffic from VPC",
      from_port   = 0,
      to_port     = 0,
      protocol    = "all",
      cidr_blocks = ["10.0.0.0/8"]
    },
  ]
  egress_rules_base = [
    {
      description = "All traffic to anywhere",
      from_port   = 0,
      to_port     = 0,
      protocol    = "-1",
      cidr_blocks = ["0.0.0.0/0"]
    },
  ]

}

 */
# ---------------------------------------------------------------------------------
# Create Global Resources such as S3 Buckets, DNS Private hosted zone, EFS etc.
#----------------------------------------------------------------------------------

# module "create_global_resources" {
#   source           = "../../../Modules/global"
#   env              = var.environment
#   envtag           = var.envtag
#   s3_buckets_names = var.s3_buckets_list
#   s3_iam_role_arn  = module.iam_roles.iam_role_arn
#   vpc_id           = var.vpc_id
# }


# ----------------------------------------------------------------------------------------------------
# Placeholder for FSX
# ----------------------------------------------------------------------------------------------------
module "Fsx" {
  source          = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-fsx-windows-file-system-managed-ad.git"
  name_tag        = "${var.app}-fsx-${var.environment}"
  environment_tag = var.environment
  deployment_type = var.fsx_deployment_type
  #kmskey_id                       = "ctx-infra-kp"
  storage_type                    = var.fsx_storage_type
  storage_capacity                = var.fsx_storage_capacity
  subnet_ids                      = var.fsx_subnets
  throughput_capacity             = var.fsx_throughput_capacity
  skip_final_backup               = true
  automatic_backup_retention_days = 2
  active_directory_id             = var.aws_directory_service_directory_id
  security_group_ids              = [module.security_group_packer.security_group_id]
}


# ----------------------------------------------------------------------------------------------------
# IAM Roles
# ----------------------------------------------------------------------------------------------------

# Basic IAM role for Web ec2 instance including instance from ASG group

resource "aws_iam_role" "ec2_app1_role" {
  name = "ec2_app1_role"
  tags = var.eH_std_tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  inline_policy {
    name        = "poc-ec2-tagging-policy"
    description = "Allowing ec2 to update license status by tagging"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "Tagging",
          "Effect" : "Allow",
          "Action" : [
            "ec2:DeleteTags",
            "ec2:CreateTags"
          ],
          "Resource" : "*"
        }
      ]
    })
  }

  inline_policy {
    name        = "poc-ec2-put-ssmpara-policy"
    description = "Allowing update the latest AMI id SSM parameter when the AMI creation succeeded"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "PutParameters",
          "Effect" : "Allow",
          "Action" : [
            "ssm:PutParameter",
            "ssm:DeleteParameter",
            "ssm:DescribeParameters",
            "ssm:GetParameters",
            "ssm:GetParameter",
            "ssm:DeleteParameters"
          ],
          "Resource" : "*"
        }
      ]
    })
  }

  inline_policy {
    name        = "poc-ec2-eventbus-policy"
    description = ""
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "VisualEditor0",
          "Effect" : "Allow",
          "Action" : [
            "events:InvokeApiDestination",
            "events:EnableRule",
            "events:CreateApiDestination",
            "events:StartReplay",
            "events:DeactivateEventSource",
            "events:PutRule",
            "events:DescribePartnerEventSource",
            "events:DescribeConnection",
            "events:UpdateArchive",
            "events:DeletePartnerEventSource",
            "events:ListPartnerEventSourceAccounts",
            "events:UpdateApiDestination",
            "events:DescribeReplay",
            "events:CancelReplay",
            "events:RemoveTargets",
            "events:ListTargetsByRule",
            "events:DescribeApiDestination",
            "events:DisableRule",
            "events:PutEvents",
            "events:CreatePartnerEventSource",
            "events:DescribeRule",
            "events:CreateArchive",
            "events:CreateEventBus",
            "events:DeauthorizeConnection",
            "events:DescribeEventSource",
            "events:ActivateEventSource",
            "events:DescribeEventBus",
            "events:TagResource",
            "events:DeleteRule",
            "events:PutTargets",
            "events:CreateConnection",
            "events:DeleteApiDestination",
            "events:DescribeArchive",
            "events:DeleteEventBus",
            "events:ListTagsForResource",
            "events:DeleteConnection",
            "events:DeleteArchive",
            "events:UpdateConnection",
            "events:UntagResource"
          ],
          "Resource" : "arn:aws:events:*:${var.account_id}:event-bus/*"
        },
        {
          "Sid" : "VisualEditor1",
          "Effect" : "Allow",
          "Action" : [
            "events:ListApiDestinations",
            "events:PutPartnerEvents",
            "events:ListRuleNamesByTarget",
            "events:ListReplays",
            "events:ListPartnerEventSources",
            "events:ListEventSources",
            "events:ListConnections",
            "events:ListRules",
            "events:ListEventBuses",
            "events:ListArchives",
            "events:TestEventPattern"
          ],
          "Resource" : "*"
        }
      ]
    })
  }

  inline_policy {
    name        = "poc-ec2-access-kms-policy"
    description = "Allowing KMS key store"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "kms:Decrypt"
          ],
          "Resource" : [
            "arn:aws:kms:ap-southeast-2:${var.account_id}:key/*"
          ]
        }
      ]
    })
  }

  /*  inline_policy { 
    name = "poc-ec2-ec2-automation-policy"
    description "Start and stop instance"
    policy = jsonencode({
    "Version": "2012-10-17",
        "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:StartInstances",
                "ec2:StopInstances"
            ],
            "Resource": "arn:aws:ec2:*:*:instance/*"
        },
        {
            "Effect": "Allow",
            "Action": "ec2:DescribeInstances",
            "Resource": "*"
        }
    ]
        ]
    })
  } */

  /* 
 inline_policy { 
    name = "poc-ec2-ssm-policy"
    description "Session Manager permissions"
    policy = jsonencode({
    "Version": "2012-10-17",
        "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetEncryptionConfiguration"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt"
            ],
            "Resource": "arn:aws:kms:ap-southeast-2:497427545767:key/5c9205e3-f50c-4a95-be9d-c6b85da65bdf"
        }
        ]
    })
  } */

}

resource "aws_iam_role_policy_attachment" "role-policy-attachment" {
  role       = "ec2_app1_role"
  count      = length(var.iam_policy_arn)
  policy_arn = var.iam_policy_arn[count.index]

}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_app1_role.name
  tags = var.eH_std_tags
}

resource "aws_iam_role" "RDS_app1_role" {

  name = "${var.environment}_RDS_app1_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# ----------------------------------------------------------------------------------------------------
# Placeholder for SSRS Server Configuration
# ----------------------------------------------------------------------------------------------------
data "aws_ami" "windows" {
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
    name   = "name"
    values = ["app1-web-AMI-*"]
  }

}

resource "aws_instance" "APP1TTITEH002" {
  ami                                  = data.aws_ami.windows.id
  instance_type                        = var.app_instance_type
  subnet_id                            = var.vpc_subnet1
  vpc_security_group_ids               = [module.security_group_packer.security_group_id]
  user_data                            = base64encode(file("ssrs_config.ps1"))
  associate_public_ip_address          = false
  monitoring                           = false
  key_name                             = "APP1ssrs"
  instance_initiated_shutdown_behavior = ""
  iam_instance_profile                 = "ec2_profile"

  tags = {
    Name = "ssrs_report5"
  }
}
resource "aws_ebs_volume" "SSRS" {
  availability_zone = "ap-southeast-2a"
  size              = 50
}
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.SSRS.id
  instance_id = aws_instance.APP1TTITEH002.id
}



# ----------------------------------------------------------------------------------------------------
# Placeholder for Security Groups
# ----------------------------------------------------------------------------------------------------



# ----------------------------------------------------------------------------------------------------
# Placeholder for EC2 Stack
# ----------------------------------------------------------------------------------------------------
/*
module "EC2_Stack" {
  source              = "../../../Modules/EC2_Stack"
  appname             = var.app
  environment         = var.environment
  instancerole        = "app1-web"
  max_size            = 1
  min_size            = 1
  desired_size        = 1
  instance_type       = var.app_instance_type
  alb_security_groups = [module.security_group_packer.security_group_id]
  ec2_instance_role   = aws_iam_instance_profile.ec2_profile.arn
  subnet_list         = var.subnets
}
*/
# ----------------------------------------------------------------------------------------------------
# Placeholder for RDS
# ----------------------------------------------------------------------------------------------------

/* module "rds_mssql_server" {
  source                          = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-rds-mssql.git"
  vpc_id                          = var.vpc_id
  subnet_group_subnet_ids         = var.db_subnet_group_subnet_ids
  environment_tag                 = var.environment_tag
  name_tag                        = var.db_name_tag
  deploy_using_snapshot           = var.deploy_using_snapshot
  rds_instance_identifier         = var.rds_instance_identifier
  domain_join_rds_iam_role        = var.domain_join_rds_iam_role
  active_directory_id             = var.aws_directory_service_directory_id
  database_username               = var.database_username
  database_cred_ssm_parameter     = var.database_cred_ssm_parameter
  database_port                   = var.database_port
  option_group_name               = aws_db_option_group.optiongroup.id
  engine                          = var.engine
  engine_version                  = var.engine_version
  instance_class                  = var.instance_class
  allocated_storage               = var.allocated_storage
  max_allocated_storage           = var.max_allocated_storage
  character_set_name              = var.character_set_name
  timezone                        = var.timezone
  iops                            = var.iops
  storage_encrypted               = var.storage_encrypted
  kms_key_name                    = var.kms_key_name
  license_model                   = var.license_model
  multi_az                        = var.multi_az
  publicly_accessible             = var.publicly_accessible
  deletion_protection             = var.deletion_protection
  allow_major_version_upgrade     = var.allow_major_version_upgrade
  auto_minor_version_upgrade      = var.auto_minor_version_upgrade
  copy_tags_to_snapshot           = var.copy_tags_to_snapshot
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = var.final_snapshot_identifier
  apply_immediately               = var.apply_immediately
  maintenance_window              = var.maintenance_window
  enhanced_monitoring_interval    = var.enhanced_monitoring_interval
  backup_retention_period         = var.backup_retention_period
  backup_window                   = var.backup_window
  db_parameter_group_family       = var.db_parameter_group_family
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_kms_key_id
  optional_tags                   = merge(var.eH_std_tags, var.db_instance_tags)
  #db_parameter_group_parameters      = var.db_parameter_group_parameters
  sg_rds_access_ingress_custom_rules = var.sg_rds_access_ingress_custom_rules
  sg_rds_access_egress_custom_rules  = var.sg_rds_access_egress_custom_rules
}
 */


# --------------------------------------------------------------------------------------------------
#  SNS and Event
# ---------------------------------------------------------------------------------------------------

resource "aws_sns_topic" "WebAMINotificationTopic" {
  name = "${var.environment}-${var.appname}-WebAMI-Notify"
}

resource "aws_sns_topic_subscription" "WebAMITopicSubs-Email" {
  topic_arn = aws_sns_topic.WebAMINotificationTopic.arn
  protocol  = "email"
  endpoint  = "marco.w.liew@gmail.com"
}

resource "aws_sns_topic_subscription" "WebAMITopicSubs-SMS" {
  topic_arn = aws_sns_topic.WebAMINotificationTopic.arn
  protocol  = "sms"
  endpoint  = "+610451050619"
}

resource "aws_sns_topic_policy" "WebAMINotificationTopicPolicy" {
  arn = aws_sns_topic.WebAMINotificationTopic.arn

  policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" = [
      {
        "Action" : "sns:Publish",
        "Resource" : aws_sns_topic.WebAMINotificationTopic.arn,
        "Principal" = {
          "Service" = "events.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : "My-statement-id"
      }
    ]

  })

}

# Rule for latest app1 web AMI id update from parameter /poc/web/amiid/latest
resource "aws_cloudwatch_event_rule" "WebAMIUpdateEvent" {
  name        = "${var.environment}-${var.appname}-WebAMIUpdateEvent"
  description = "This will be trigger when a new app1 Web AMI image created and the /poc/web/amiid/latest parameter updated successfully."

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
          "/poc/web/amiid/latest"
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
  arn = aws_sns_topic.WebAMINotificationTopic.arn
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
  name        = "${var.environment}-${var.appname}-WebAMIFailEvent"
  description = "This will be trigger when codepipeline failed to create new AMI image in a transaction."

  event_pattern = <<EOF
  {
    "detail-type": [
      "AmiBuilder"
    ],
    "source": [
      "poc.app1.ami.codebuild"
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
  arn = aws_sns_topic.WebAMINotificationTopic.arn
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
  name        = "${var.environment}-${var.appname}-WebAMISucceedEvent"
  description = "This will be trigger when codepipeline succeeded to create new AMI image in a transaction."

  event_pattern = <<EOF
  {
    "detail-type": [
      "AmiBuilder"
    ],
    "source": [
      "poc.app1.ami.codebuild"
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
  arn = aws_sns_topic.WebAMINotificationTopic.arn
  input_transformer {
    input_paths = {
      resources = "$.resources"
    }
    input_template = "\" New Web Server AMI has been created: <resources>. \""
  }
}

# ----------------------------------------------------------------------------------------------------
# ASG LB AMI and ACM
# ----------------------------------------------------------------------------------------------------

data "aws_acm_certificate" "app1web" {
  domain = "*.nswhealth.net"
  #types    = ["Imported"]
  #statuses = ["ISSUED"]
  #most_recent = true
}

# Use SSM parameter instead for latest AMI id

/* data "aws_ami" "windows" {
  owners      = ["497427545767"]
  most_recent = "true"
  filter {
    name = "name"
    values = ["poc-app1-web-AMI-*"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}
 */

data "aws_ssm_parameter" "Web_AMI_id_latest" {
  name = var.ssm_para_webamiid_latest
}

resource "aws_autoscaling_lifecycle_hook" "hook_INSTANCE_TERMINATING" {
  name                   = "LCH_EC2_INSTANCE_TERMINATING"
  autoscaling_group_name = aws_autoscaling_group.app1-WEB-ASG.name
  default_result         = "CONTINUE"
  heartbeat_timeout      = 2000
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
  #notification_target_arn = aws_cloudwatch_event_target.target_ssm_clean.arn
  #role_arn                = aws_iam_role.event_ADObject_clean_role.arn
}

resource "aws_cloudwatch_event_rule" "SSM_ASG_Termination" {
  name        = "${var.environment}-${var.appname}-ssmasg-termination"
  description = "This will be trigger when a Web server taken off ASG."

  event_pattern = <<EOF
	{
    "detail-type": [
      "EC2 Instance-terminate Lifecycle Action"
    ],
    "source": [
      "aws.autoscaling"
    ],
    "detail": {
      "AutoScalingGroupName": [
        "poc-asg-web"
      ]
    }
  }
    EOF
}

resource "aws_cloudwatch_event_target" "target_ssm_clean" {
  rule      = aws_cloudwatch_event_rule.SSM_ASG_Termination.name
  target_id = "${var.environment}-${var.appname}-ADClean-ssmcall"
  arn       = aws_ssm_document.AD_Clean.arn #SSM document , to be added.
  role_arn  = aws_iam_role.event_ADObject_clean_role.arn
  input_transformer {
    input_paths = {
      instanceid = "$.detail.EC2InstanceId"
    }

    input_template = "\"InstanceId\":[<instanceid>]"
  }
}

resource "aws_iam_role" "event_ADObject_clean_role" {
  name = "${var.environment}-${var.appname}-event-ADObject-clean"
  tags = var.eH_std_tags

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "events.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
  inline_policy { #tbd
    name = "Start-SSM-Automation-Policy"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "ssm:StartAutomationExecution"
          ],
          "Resource" : "arn:aws:ssm:ap-southeast-2:497427545767:automation-definition/poc-app1-cf-ADObject-clean-document-PlvBWwwQeGfR:$DEFAULT", # to be update
          "Effect" : "Allow"
        }
      ]
    })
  }

  inline_policy {
    name = "Pass-Role-SSM-Automation-Policy"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "iam:PassRole"
          ],
          "Resource" : "arn:aws:iam::497427545767:role/poc-app1-cf-ADObject-clean-AutomationAssumeRole-1U3YIIMVDGV91",
          "Effect" : "Allow"
        }
      ]
    })
  }

}

resource "aws_ssm_document" "foo" {
  name          = "${var.environment}-${var.appname}-ADObject-clean-doc"
  document_type = "Command"

  content = <<DOC
{
  "outputs": [
    "createAMI.ImageId"
  ],
  "schemaVersion": "0.3",
  "description": "This document will disjoin instances From an Active Directory, send a signal to the LifeCycleHook to terminate the instance",
  "assumeRole": "{{AutomationAssumeRole}}",
  "parameters": {
    "AutomationAssumeRole": {
      "default": "arn:aws:iam::497427545767:role/poc-app1-cf-ADObject-clean-AutomationAssumeRole-1U3YIIMVDGV91",
      "description": "(Required) The ARN of the role that allows Automation to perform the actions on your behalf.",
      "type": "String"
    },
    "ASGName": {
      "default": "${aws_autoscaling_group.app1-WEB-ASG.name}}",
      "description": "The name of the AutoScaling Group.",
      "type": "String"
    },
    "InstanceId": {
      "type": "String"
    },
    "LCHName": {
      "default": "LCH_EC2_INSTANCE_TERMINATING",
      "description": "The name of the Life Cycle Hook.",
      "type": "String"
    }
  },
  "mainSteps": [
    {
      "inputs": {
        "Parameters": {
          "executionTimeout": "7200",
          "commands": [
            "$name = $env:computerName",
            "$PartOfDomain = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain",
            "if($PartOfDomain -eq $true){",
            "$secrets_manager_secret_id = \"poc/adcred\"",
            "$secret_manager = Get-SECSecretValue -SecretId $secrets_manager_secret_id",
            "$secret = $secret_manager.SecretString | ConvertFrom-Json",
            "$username = $secret.admuser",
            "$password = $secret.admpwd | ConvertTo-SecureString -AsPlainText -Force",
            "$credential = New-Object System.Management.Automation.PSCredential($username,$password)",
            "Write-Output \"Removing computer $name from the domain\"",
            "Remove-ADComputer -Identity $name -Credential $credential -Confirm:$False",
            "Remove-Computer -ComputerName $name -Credential $credential -PassThru -Restart -Force}",
            "else{",
            "Write-Output \"Cannot remove computer $name because it is not in a domain\"}"
          ]
        },
        "InstanceIds": [
          "{{ InstanceId }}"
        ],
        "DocumentName": "AWS-RunPowerShellScript"
      },
      "name": "RunCommand",
      "action": "aws:runCommand"
    },
    {
      "inputs": {
        "ImageName": "{{ InstanceId }}_{{automation:EXECUTION_ID}}",
        "InstanceId": "{{ InstanceId }}",
        "ImageDescription": "My newly created AMI - ASGName: {{ ASGName }}",
        "NoReboot": true
      },
      "name": "createAMI",
      "action": "aws:createImage"
    },
    {
      "inputs": {
        "LifecycleHookName": "{{ LCHName }}",
        "InstanceId": "{{ InstanceId }}",
        "AutoScalingGroupName": "{{ ASGName }}",
        "Service": "autoscaling",
        "Api": "CompleteLifecycleAction",
        "LifecycleActionResult": "CONTINUE"
      },
      "name": "TerminateTheInstance",
      "action": "aws:executeAwsApi"
    }
  ]
}
DOC
}

resource "aws_autoscaling_group" "app1-WEB-ASG" {
  name                      = "${var.environment}-${var.appname}-web-asg"
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  health_check_grace_period = var.asg_check_period
  health_check_type         = var.asg_check_type
  desired_capacity          = var.asg_desired_size
  force_delete              = true
  launch_configuration      = aws_launch_configuration.app1-WEB-LC.name
  vpc_zone_identifier       = var.subnets
  default_cooldown          = 300
  termination_policies      = "OldestInstance"
  load_balancers            = "poc-app1-web-alb"
  tag {
    key                 = "name"
    value               = "${var.environment}-${var.appname}-web-asg"
    propagate_at_launch = true
  }
  timeouts {
    delete = "15m"
  }
}

resource "aws_security_group" "app1_web_sg" {
  name        = "${var.environment}_${var.appname}_sg"
  description = "Allow inbound traffic to app1 web server"
  vpc_id      = var.vpc_id

  ingress {
    description = "All http traffic from health LAN"
    port        = "80"
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/8"]

  }

  ingress {
    description = "All https traffic from health LAN"
    port        = "443"
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/8"]

  }

  ingress {
    description     = "All https traffic from Load Balancer"
    port            = "443"
    protocol        = "TCP"
    security_groups = [aws_security_group.app1_lb_web_sg.name]

  }

  ingress {
    description     = "All http traffic from Load Balancer"
    port            = "80"
    protocol        = "TCP"
    security_groups = [aws_security_group.app1_lb_web_sg.name]

  }

  egress {
    description = "All traffic to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  /*   tags = {
    Name = "app1_sg"
  } */
}

resource "aws_security_group" "app1_lb_web_sg" { #done
  name        = "${var.environment}_${var.appname}_lb_sg"
  description = "Allow inbound traffic to app1 web server"
  vpc_id      = var.vpc_id

  ingress {
    description = "All http traffic from health LAN"
    port        = "80"
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/8"]

  }

  ingress {
    description = "All https traffic from health LAN"
    port        = "443"
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/8"]

  }

  egress {
    description = "All traffic to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  /*   tags = {
    Name = "app1_sg"
  } */
}

resource "aws_launch_configuration" "app1-WEB-LC" {
  name_prefix          = "${var.environment}-${var.appname}-Web-lc"
  image_id             = data.aws_ssm_parameter.Web_AMI_id_latest.name
  instance_type        = var.asg_instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_profile
  user_data            = base64encode(file("userdata_web.ps1")) #tbd
  security_groups      = aws_security_group.app1_web_sg.id
  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = "50"
  }
}


resource "aws_lb" "alb" { # not done
  name               = "${var.appname}-${var.instancerole}-${var.environment}-ALB"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app1_lb_web_sg.id]
  subnets            = var.subnets

  enable_deletion_protection = true

  tags = {
    Environment = var.environment
    Name        = "${var.appname}-${var.instancerole}-${var.environment}-ALB"
  }
}
