environment              = "poc"
envtag                   = "poc"
appname                  = "app1"
asg_max_size             = "1"
asg_min_size             = "1"
asg_desired_size         = "1"
asg_check_period         = "300"
asg_check_type           = "EC2"
asg_instance_type        = "t2.medium"
ssm_para_webamiid_latest = "/poc/web/amiid/latest"
vpc_id                   = "vpc-00000000000000000"
s3_tfstate_bucket        = "poc-app1-tfstate-test-bucket"
dynamo_db_table_name     = "poc-app1-test-lockDynamo"
git_source_code_bucket   = "poc-git-health-code-app1"
account_id               = "497427545767"
github_pat               = "/POC/test/pat"
subnets                  = ["subnet-08152d834ac1d66d6", "subnet-084a8e9d59f34a961", "subnet-08537464c70ca9c90"]
vpc_subnet1              = "subnet-08152d834ac1d66d6" #ap-southeast-2a
vpc_subnet2              = "subnet-084a8e9d59f34a961" #ap-southeast-2b
vpc_subnet3              = "subnet-08537464c70ca9c90" #ap-southeast-2c
s3_buckets_list          = []
eH_std_tags = {
  "BillingCustomer"          = "John Smith"
  "CostCenter"               = "000000"
  "DemandID"                 = "TBD"
  "Environment"              = "Poc"
  "OracleProjectCode"        = "TBD"
  "OracleProjectTaskID"      = "TBD"
  "ServiceOffering"          = "TBD"
  "aws-migration-project-id" = "TBD"
  "map-migrated-app"         = "TBD"
  "DR"                       = "TBD"
  "Owner"                    = "Dummy Manzar"
  "ServiceClass"             = "TBD"
  "ApplicationName"          = "app1"
  "Approver"                 = "John Smith"
  "BusinessUnit"             = "EH-SD-CAS"
  DR                         = "Critical"
}
iam_policy_arn = [
  "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
  "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
  "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess"
]

# ingress_rules_additional        = [
# {
#     description = "in-https-cidr-allprivate",
#     from_port   = "443",
#     to_port     = "443",
#     protocol    = "tcp",
#     cidr_blocks = ["10.0.0.0/8"]
# },
# ]

# RDS values
environment_tag = "poc"
db_name_tag     = "sqldbaw-app1WS-poc-001"
db_instance_tags = {
  DBType  = "RDS"
  Engine  = "sqlserver-se"
  Version = "15.00.4073.23.v1"
}
rds_instance_identifier     = "sqldbaw-app1WS-poc-001"
database_username           = "admin"
database_cred_ssm_parameter = "/test/app1/RDS"
# vpc_id = already defined
database_port                   = "1433"
engine                          = "sqlserver-se"
engine_version                  = "15.00.4073.23.v1"
instance_class                  = "db.r5.large"
allocated_storage               = 300
db_parameter_group_family       = "sqlserver-se-15.0"
deploy_using_snapshot           = false
snapshot_id                     = ""
max_allocated_storage           = 0
storage_type                    = "gp2"
iops                            = 0
storage_encrypted               = true
kms_key_name                    = "alias/aws/rds"
license_model                   = "license-included"
multi_az                        = false
publicly_accessible             = false
deletion_protection             = true
auto_minor_version_upgrade      = false
allow_major_version_upgrade     = false
skip_final_snapshot             = false
apply_immediately               = false
maintenance_window              = "Sat:16:05-Sat:19:00"
enhanced_monitoring_interval    = 60
enabled_cloudwatch_logs_exports = []
backup_retention_period         = 7
backup_window                   = "15:00-16:00" //UTC Time - Daily 1am-2am AEST
db_parameter_group_parameters   = []
db_parameter_group_name         = null
db_subnet_group_name            = null
# option_group_name                    = ""
db_subnet_group_subnet_ids           = ["subnet-3333333333333333", "subnet-3333333333333333", "subnet-3333333333333333"]
default_ingress_protocol             = "tcp"
default_ingress_enable_allow_self_sg = true
default_ingress_rds_sg_access_list   = []
sg_rds_access_ingress_custom_rules = [
  {
    description = "db entry point - sg custom",
    from_port   = 1433,
    to_port     = 1433,
    protocol    = "tcp",
    cidr_blocks = ["10.0.0.0/8"]
  }
]
sg_rds_access_egress_custom_rules = [
  {
    description = "RDS to Managed AD - sg custom",
    from_port   = 0,
    to_port     = 0,
    protocol    = "-1",
    cidr_blocks = ["10.0.0.0/8"]
  }
]
final_snapshot_identifier             = "final-snapshot"
character_set_name                    = "SQL_Latin1_General_CP1_CI_AS"
copy_tags_to_snapshot                 = true
performance_insights_enabled          = false
performance_insights_retention_period = 0
performance_insights_kms_key_id       = ""
create_timeout                        = "2h"
update_timeout                        = "2h"
delete_timeout                        = "2h"
# active_directory_id = null
domain_join_rds_iam_role     = "rds-directoryservice-access-role"
iam_role_rds_monitoring_name = null
timezone                     = "AUS Eastern Standard Time"
availability_zone            = null

/*eH_std_tags = {
  BillingCustomer     = "John Smith"
  CostCenter          = "000000"
  DemandID            = "RITM111111111"
  Environment         = "poc"
  OracleProjectCode   = "EH SD CAS BAU Rostering"
  OracleProjectTaskID = "07.5.5"
  ServiceOffering     = "Managed"
  DR                  = "Critical"
  Owner               = "Bonwyn Culling"
  ServiceClass        = "Gold"
  ApplicationName     = ""
  Approver            = "John Smith"
  BusinessUnit        = "EH-SD-CAS"
  DR                  = "Critical"
}*/

# DB Option group values
create_db_option_group   = true
engine_name              = "sqlserver-se"
major_engine_version     = "15.00"
option_group_name        = "sqlnativebackups"
option_group_description = "Enable AWS RDS SQL backup to S3"
options                  = "SQLSERVER_BACKUP_RESTORE"
use_name_prefix          = false