# # ----------------------------------------------------------------------------------------------------
# # Placeholder for RDS
# # ----------------------------------------------------------------------------------------------------

# RDS Admin password

resource "random_password" "db_master_password" {
  length           = 16
  special          = true
  override_special = "!$#%"
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
}

resource "random_password" "db_master_password_ssrs" {
  length           = 30
  special          = true
  override_special = "!$#%.()"
  min_lower        = 5
  min_numeric      = 5
  min_special      = 5
  min_upper        = 5
}


resource "aws_ssm_parameter" "db_secret" {
  name        = "/${local.resource_prefix}/database/password/master"
  description = "SQL admin password"
  type        = "SecureString"
  value       = random_password.db_master_password.result
  lifecycle {
    ignore_changes = [value]
  }
  tags = var.eH_std_tags
}

resource "aws_ssm_parameter" "db_secret_ssrs" {
  name        = "/${local.resource_prefix}/ssrs_db/password/master"
  description = "SQL admin password"
  type        = "SecureString"
  value       = random_password.db_master_password_ssrs.result
  lifecycle {
   ignore_changes = [value]
  }
  tags = var.eH_std_tags
}



#RDS Random Passwords for Secret Store

resource "random_password" "Tissrspwd" {
  length           = 10
  special          = true
  override_special = "!$#%"
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
}
resource "random_password" "TiWebpwd" {
  length           = 10
  special          = true
  override_special = "!$#%"
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
}
resource "random_password" "TiDentalpwd" {
  length           = 10
  special          = true
  override_special = "!$#%"
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
}

resource "random_password" "SSRSenc" {
  length           = 10
  special          = true
  override_special = "!$#%"
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
}


resource "aws_secretsmanager_secret" "DBcreds" {
  name        = "/${local.resource_prefix}/sqldb/creds"
  description = "SQL Database credentials"
  recovery_window_in_days = 0
  tags        = var.eH_std_tags

}

resource "aws_secretsmanager_secret_version" "DBcreds" {
  secret_id     = aws_secretsmanager_secret.DBcreds.id
  secret_string = <<EOF
   {
    "Tissrsuser": "TISSRSUSER",
    "Tissrspwd": "${random_password.Tissrspwd.result}",
    "TiWebuser": "TITANIUMWEBSERVICES",
    "TiWebpwd": "${random_password.TiWebpwd.result}",
    "TiDentaluser": "TITANIUMDENTAL",
    "TiDentalpwd": "${random_password.TiDentalpwd.result}",
    "SSRSEncPWD": "${random_password.SSRSenc.result}"
   }
EOF
  lifecycle {
   ignore_changes = [secret_string]
  }

}

# Creating DB Option group
module "rds_options" {
  source = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-rds-options-group.git?ref=v1.0.0"
  #db_option_group_name = var.option_group_name
  name_tag             = var.opt_name_tag
  environment_tag      = var.environment_tag
  major_engine_version = var.major_engine_version
  engine               = var.engine
  db_option_group_options = [
    {
      option_name = "SQLSERVER_BACKUP_RESTORE"
      option_setting = [{
        name  = "IAM_ROLE_ARN"
        value = aws_iam_role.RDS_app1_role.arn
      }]
    },

  ]

  optional_tags = var.eH_std_tags
}


module "rds_mssql_server" {
  source                             = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-rds-mssql.git?ref=v2.2.0"
  vpc_id                             = var.vpc_id
  subnet_group_subnet_ids            = var.db_subnet_group_subnet_ids
  environment_tag                    = var.environment_tag
  name_tag                           = var.db_name_tag
  deploy_using_snapshot              = var.deploy_using_snapshot
  rds_instance_identifier            = var.rds_instance_identifier
  no_rds_identifier_prefix           = var.no_rds_identifier_prefix
  domain_join_rds_iam_role           = aws_iam_role.RDS_app1_role.name
  active_directory_id                = var.aws_directory_service_directory_id
  database_username                  = var.database_username
  database_cred_ssm_parameter        = aws_ssm_parameter.db_secret.name
  database_port                      = var.database_port
  option_group_name                  = module.rds_options.db_option_group_id
  engine                             = var.engine
  engine_version                     = var.engine_version
  instance_class                     = var.instance_class
  allocated_storage                  = var.allocated_storage
  max_allocated_storage              = var.max_allocated_storage
  character_set_name                 = var.character_set_name
  timezone                           = var.timezone
  iops                               = var.iops
  storage_encrypted                  = var.storage_encrypted
  kms_key_name                       = var.kms_key_name
  license_model                      = var.license_model
  multi_az                           = var.multi_az
  publicly_accessible                = var.publicly_accessible
  deletion_protection                = var.deletion_protection
  allow_major_version_upgrade        = var.allow_major_version_upgrade
  auto_minor_version_upgrade         = var.auto_minor_version_upgrade
  copy_tags_to_snapshot              = var.copy_tags_to_snapshot
  skip_final_snapshot                = var.skip_final_snapshot
  final_snapshot_identifier          = var.final_snapshot_identifier
  apply_immediately                  = var.apply_immediately
  maintenance_window                 = var.maintenance_window
  enhanced_monitoring_interval       = var.enhanced_monitoring_interval
  backup_retention_period            = var.backup_retention_period
  backup_window                      = var.backup_window
  db_parameter_group_family          = var.db_parameter_group_family
  performance_insights_enabled       = var.performance_insights_enabled
  optional_tags                      = merge(var.eH_std_tags, var.db_instance_tags)
  db_parameter_group_parameters      = var.db_parameter_group_parameters
  rds_additional_security_group_ids     = local.rds_security_ids
  depends_on = [
    aws_ssm_parameter.db_secret, aws_iam_role.RDS_app1_role, aws_iam_role_policy_attachment.sql_ds_policy_attachment
  ]
}



# Read-Only Replica for Titanium Reporting

module "rds_sql_server_Replica" {
  source                             = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-rds-mssql?ref=v2.2.0"
  vpc_id                             = var.vpc_id
  subnet_group_subnet_ids            = var.db_subnet_group_subnet_ids
  replicate_source_rds_identifier    = var.rds_instance_identifier
  environment_tag                    = var.environment
  name_tag                           = var.rds_instance_identifier_ro
  deploy_using_snapshot              = false
  db_parameter_group_family          = var.db_parameter_group_family
  rds_instance_identifier            = var.rds_instance_identifier_ro
  active_directory_id                = var.aws_directory_service_directory_id
  domain_join_rds_iam_role           = aws_iam_role.RDS_app1_role.name
  iam_role_rds_monitoring_name       = "${local.resource_prefix}-rds-monitoring-role"
  database_username                  = var.database_username
  database_cred_ssm_parameter        = aws_ssm_parameter.db_secret.name
  database_port                      = var.database_port
  option_group_name                  = module.rds_options.db_option_group_id
  engine                             = var.engine
  engine_version                     = var.engine_version
  instance_class                     = var.instance_class
  allocated_storage                  = var.allocated_storage
  max_allocated_storage              = var.max_allocated_storage
  character_set_name                 = var.character_set_name
  timezone                           = var.timezone
  iops                               = var.iops
  storage_encrypted                  = var.storage_encrypted
  kms_key_name                       = var.kms_key_name
  multi_az                           = false
  deletion_protection                = var.deletion_protection
  allow_major_version_upgrade        = var.allow_major_version_upgrade
  auto_minor_version_upgrade         = var.auto_minor_version_upgrade
  copy_tags_to_snapshot              = var.copy_tags_to_snapshot
  skip_final_snapshot                = var.skip_final_snapshot
  final_snapshot_identifier          = var.final_snapshot_identifier
  apply_immediately                  = var.apply_immediately
  maintenance_window                 = var.maintenance_window
  enhanced_monitoring_interval       = var.enhanced_monitoring_interval
  backup_retention_period            = 0 # backups not supported on read_replicas
  performance_insights_enabled       = var.performance_insights_enabled
  optional_tags                      = merge(var.eH_std_tags, var.db_instance_ro_tags)
  rds_additional_security_group_ids     = local.rds_security_ids
  no_rds_identifier_prefix           = true
  #rds_additional_security_group_ids     = [sg-111111111]
  depends_on = [module.rds_mssql_server]
}


module "databases_backup_plan" {
  source            = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-backup-config.git?ref=v1.0.0"
  environment_tag   = var.environment
  vault_name_prefix = local.resource_prefix
  enabled           = var.backup_enabled
  kms_key_arn       = aws_kms_key.rds.arn
  depends_on               = [aws_kms_key.rds]

  rules = [
    {
      name              = "databases-weekly-backup-rule"
      schedule          = var.backup_weekly_schedule
      start_window      = var.backup_start_window
      completion_window = var.backup_completion_window
      lifecycle = {
        cold_storage_after = 0
        delete_after       = var.backup_weekly_retention
      }
      recovery_point_tags = merge({ BackupType = "weekly" }, var.eH_std_tags)
    },
    {
      name              = "databases-monthly-backup-rule"
      schedule          = var.backup_monthly_schedule
      start_window      = var.backup_start_window
      completion_window = var.backup_completion_window
      lifecycle = {
        cold_storage_after = 0
        delete_after       = var.backup_monthly_retention
      }
      recovery_point_tags = merge({ BackupType = "monthly" }, var.eH_std_tags)
    },
  ]

  # Multiple selections
  # Daily, Weekly, Monthly and Yearly Backups and retention
  selections = [
    {
      name = "databases_backup_selection"
      selection_tag = {
        type  = "STRINGEQUALS"
        key   = "backup-plan"
        value = "databases"
      }
    },
  ]
  optional_tags = var.eH_std_tags
}


#KMS Key
resource "aws_kms_key" "rds" {
  description              = var.kms_description
  customer_master_key_spec = var.key_spec
  is_enabled               = var.kms_enabled
  enable_key_rotation      = var.kms_rotation_enabled
  tags                     = var.eH_std_tags
  policy                   = data.aws_iam_policy_document.rds_cmk_access.json
  depends_on               = [aws_iam_role.ec2_app1_role]
}

# Add an alias to the key
resource "aws_kms_alias" "rds" {
  name          = "alias/${local.resource_prefix}-rds"
  target_key_id = aws_kms_key.rds.key_id
}





data "aws_iam_policy_document" "rds_cmk_access" {
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
}
