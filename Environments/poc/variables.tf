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
variable "subnets" {
  type = list(string)
}

variable "fsx_subnets" {}

variable "app_instance_type" {
  type        = string
  description = "EC2 instance type for Application Server"
}
variable "s3_buckets_list" {
  type        = list(string)
  description = "List of S3 buckets to be created"
}
variable "domain" {
  description = "The ID of the Directory Service Active Directory domain to create the instance in"
  type        = string
}
variable "domain_iam_role_name" {
  description = "(Required if domain is provided) The name of the IAM role to be used when making API calls to the Directory Service"
  type        = string
}
variable "ingress_rules_additional" {
  description = "A list of security group additional ingress rules. It is intended to define additional rules which are set in tfvars.Requires from_port, to_port, protocol and either one of security_groups or cidr_blocks arguments. self argument can be used together with security_groups or cidr_blocks."
  type        = any
  default     = []
}

variable "fsx_storage_capacity" {
  type        = number
  description = "storage capacity of fsx in GB"
}

#variable "subnet_ids" {
# default = ["subnet-08152d834ac1d66d6"]
#}

variable "fsx_throughput_capacity" {
  type        = number
  description = "storage capacity of fsx in GB"
}

variable "fsx_deployment_type" {
  type        = string
  description = "Let us know whether fsx is a Multi-AZ or Single-AZ "
}

variable "fsx_storage_type" {
  type        = string
  description = "Let us know whether fsx is a Multi-AZ or Single-AZ "
}

#variable "security_groups" {
# default = ["sg-0412bd4d135a54165"]
#}

variable "aws_directory_service_directory_id" {
  type        = string
  description = " Active directory ID for authentication"
}

variable "aws_kmskey_id" {
  type        = string
  description = "KMS Key ID for encryption"
}

#variable "latest_hardenedwin2016_id" {
# default = "ami-0651aff3a92541a22"
#}

#variable "default_instance_profile" {
#  default = "EC2INIT"
#}

#variable "default_key_pair" {
# default = "default-kp"
#}

#variable "ec2_instance_role" {}

variable "iam_policy_arn" {
  description = "IAM Policy to be attached to EC2 role"
  type        = list(string)
}
variable "appname" {
  default = "app1"

  variable "app" {
    type        = string
    description = "Applicatio name"
  }

  variable "asg_max_size" {
    default = "1"
  }

  variable "asg_min_size" {
    default = "1"
  }

  variable "asg_desired_size" {
    default = "1"
  }

  variable "asg_check_period" {
    default = "300"
  }


  variable "asg_check_type" {
    default = "EC2"
  }

  variable "webhook_filter_branch" {
    type        = string
    description = "Branch where all the latest codes will be pushed"
  }


  ######RDS Variables########################


  variable "db_instance_tags" {
    description = "Additional tags for the DB instance"
    type        = map(string)
  }

  variable "asg_instance_type" {
    type        = string
    description = "EC2 instance type for ASG"
  }

  variable "ssm_para_webamiid_latest" {
    type        = string
    description = "parameter store for latest web AMI id"
  }

}

variable "environment_tag" {
  description = "Mandatory Environment resource tag, used to explicity set Environment tag. Dev,Test,Prod,Production etc"
  type        = string
}

variable "db_name_tag" {
  description = "Optional Name resource tag. Used to explicity set Name tag"
  type        = string
}

variable "rds_instance_identifier" {
  type        = string
  description = "The name of the RDS instance"
}

variable "database_username" {
  type        = string
  description = "The master username for the DB instance."
}

variable "database_cred_ssm_parameter" {
  type        = string
  description = "AWS System Manager parameter path which contain RDS master password"
}
variable "database_port" {
  type        = number
  description = "The port on which the DB accepts connections, used in the DB Security Group to allow access to the DB instance from the provided `security_group_ids`."
}

variable "engine" {
  type        = string
  description = "The database engine to use."
}

variable "engine_version" {
  type        = string
  description = "The database engine version to use."
}

variable "instance_class" {
  type        = string
  description = "The instance type of the RDS instance. Please refer https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html"
}

variable "allocated_storage" {
  type        = number
  description = "The allocated storage in GBs."
}

variable "db_parameter_group_family" {
  type        = string
  description = "The family of the DB parameter group."
}
variable "deploy_using_snapshot" {
  type        = bool
  description = "The Switch to define if RDS database should be built using existing snapshot. Set this variable to true to build database using existing snapshot."
}

variable "snapshot_id" {
  type        = string
  description = "The ID of snapshot which will be used to build the RDS database."
}

variable "max_allocated_storage" {
  type        = number
  description = "The upper limit to which RDS can automatically scale the storage in GBs. Must be greater than or equal to allocated_storage or 0 to disable Storage Autoscaling."
}

variable "storage_type" {
  type        = string
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD)."
}

variable "iops" {
  type        = number
  description = "The amount of provisioned IOPS. Setting this implies a storage_type of 'io1'. Default is 0 if rds storage type is not 'io1'."
}

variable "storage_encrypted" {
  type        = bool
  description = "Specifies whether the DB instance is encrypted."
}

variable "kms_key_name" {
  type        = string
  description = "The Name of the existing KMS key to encrypt storage"
}

variable "license_model" {
  type        = string
  description = "License model for this DB. Optional "
}

variable "multi_az" {
  type        = bool
  description = "Specifies if the RDS instance is multi-AZ."
}

variable "publicly_accessible" {
  type        = bool
  description = "Determines if database can be publicly available (NOT recommended)."
}

variable "deletion_protection" {
  type        = bool
  description = "Determines if DB instance should have deletion protection enabled."
}

variable "auto_minor_version_upgrade" {
  type        = bool
  description = "The Switch to indicate that minor engine upgrades will be applied automatically to the DB instance during the maintenance window."
}

variable "allow_major_version_upgrade" {
  type        = bool
  description = "The Switch to indicate that major version upgrades are allowed."
}

variable "skip_final_snapshot" {
  type        = bool
  description = "The Switch to determine whether a final DB snapshot is created before the DB instance is deleted."
}

variable "apply_immediately" {
  type        = bool
  description = "The Switch to specify whether any database modifications are applied immediately, or during the next maintenance window."
}

variable "maintenance_window" {
  type        = string
  description = "Maintenance Window in UTC time. Default is set as Sat 16:05-Sat:19:00 UTC which is Sunday 2:05am-4am AEST"
}

variable "enhanced_monitoring_interval" {
  type        = number
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance."
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Set of log types to enable for exporting to CloudWatch logs. Valid values MSSQL: agent , error."
  type        = list(string)
}

variable "backup_retention_period" {
  type        = number
  description = "The days to retain backups for. Must be between 0 and 35."
}

variable "backup_window" {
  type        = string
  description = "Backup Window in UTC time."
}

variable "db_parameter_group_parameters" {
  description = "A list of DB parameters to apply. Full list of all parameters can be discovered via <aws rds describe-db-parameters> after initial creation of the group."
  type        = list(map(string))
}

variable "db_parameter_group_name" {
  type        = string
  description = "(Optional, Forces new resource) The name of the DB parameter group. If omitted, Terraform will assign a random, unique name."
}

variable "db_subnet_group_name" {
  type        = string
  description = "(Optional, Forces new resource) The name of the DB subnet group. If omitted, Terraform will assign a random, unique name."
}

variable "option_group_name" {
  type        = string
  description = "Name of the DB option group to associate. The default option group will be used for the SQL Version And Edition. RDS Options groups are attached to rds snapshots (manual and automated) - hence why they should be created outside of the module as a terraform destroy will fail unless all snapshots are deleted (which in production would not be appropriate)."
}

variable "db_subnet_group_subnet_ids" {
  type        = list(string)
  description = "List of subnets for the DB"
}

variable "default_ingress_protocol" {
  description = "Default RDS ingress security group protocol rule."
  type        = string
}

variable "default_ingress_enable_allow_self_sg" {
  description = "Default RDS ingress security group rule. If true, the security group itself will be added as a source to this ingress rule."
  type        = bool
}

variable "default_ingress_rds_sg_access_list" {
  description = "List of security group ids to be allowed access to RDS."
  type        = list(string)
}

variable "sg_rds_access_ingress_custom_rules" {
  description = "A list of custom security group ingress rules."
  type        = any
}

variable "sg_rds_access_egress_custom_rules" {
  description = "A list of custom security group egress rules."
  type        = any
}

variable "final_snapshot_identifier" {
  type        = string
  description = "The name of the final DB Snapshot when this DB instance is deleted . Must be provided if skip_final_snapshot is set to false "
}

variable "character_set_name" {
  type        = string
  description = "SQL Server Character Set name to be uses for the RDS Instance"
}

variable "copy_tags_to_snapshot" {
  type        = bool
  description = "copy tags to snapshots ( true or false)"
}

variable "performance_insights_enabled" {
  type        = bool
  description = "rds performance insights to enabled or disabled (true or false)"
}

variable "performance_insights_retention_period" {
  type        = number
  description = "number of days to retain ( Default is 7 Days)"
}

variable "performance_insights_kms_key_id" {
  type        = string
  description = "the ksm key id full aws arn address to encrypt the performance insight data"
}

variable "create_timeout" {
  type        = string
  description = "creation timeout for RDS for terraform e.g 1h, 30m"
}

variable "update_timeout" {
  type        = string
  description = "update timeout for RDS for terraform"
}

variable "delete_timeout" {
  type        = string
  description = "update timeout for RDS for terraform"
}
variable "domain_join_rds_iam_role" {
  type        = string
  description = "iam role that RDS assume to domain join to the directory id - role can be created in AWS Console"
}
variable "create_db_option_group" {
  description = "Whether to create this resource or not?"
  type        = bool

}

# variable "db_option_group_name" {
#   description = "The name of the option group"
#   type        = string

# }

variable "use_name_prefix" {
  description = "Determines whether to use `name` as is or create a unique name beginning with `name` as the specified prefix"
  type        = bool
}

variable "option_group_description" {
  description = "The description of the option group"
  type        = string

}

variable "engine_name" {
  description = "Specifies the name of the engine that this option group should be associated with"
  type        = string

}

variable "major_engine_version" {
  description = "Specifies the major version of the engine that this option group should be associated with"
  type        = string

}

variable "options" {
  description = "A list of Options to apply"
  type        = any

}

variable "iam_role_rds_monitoring_name" {
  type        = string
  description = "(Optional, Forces new resource) Friendly name of the role. If omitted, Terraform will assign a random, unique name."
}

variable "timezone" {
  type        = string
  description = "(Optional, Forces new resource) Timezone for the RDS MSSQL Instance. Default AUS Eastern Standard Time - will change during daylight savings"
}

variable "availability_zone" {
  type        = string
  description = "(Optional, Forces new resource) Set the AZ that the RDS instance will be created in, Can not use this parameter with Multi-AZ set to true."
}
