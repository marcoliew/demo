
app                    = "app1"
environment            = "prod"
lhd                    = "dependencies"
envtag                 = "prod"
vpc_id                 = "vpc-00000000000000000"
s3_tfstate_bucket      = "prod-dependencies-app1-tfstate-bucket"
artifacts_bucket       = "prod-dependencies-app1-artifacts-bucket"
dynamo_db_table_name   = "prod-dependencies-app1-lockDynamo"
git_source_code_bucket = "prod-dependencies-git-health-code-app1"
account_id             = "999999999999"
github_pat             = "/dependencies-prod-app1/PAT"
vpc_subnets            = ["subnet-aaaaaaaaaaaaaaaa", "subnet-bbbbbbbbbbbbbbb", "subnet-cccccccccccccccccc"]
vpc_subnet1            = "subnet-aaaaaaaaaaaaaaaa" #ap-southeast-2a
vpc_subnet2            = "subnet-bbbbbbbbbbbbbbb" #ap-southeast-2b
vpc_subnet3            = "subnet-cccccccccccccccccc" #ap-southeast-2c
subnets_cidr           = ["10.137.64.0/25", "10.137.64.128/25", "10.137.65.0/25"]
s3_buckets_list        = []
webhook_filter_branch  = "Production"
iam_policy_arn = [
 "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
  "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
  "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
]
aws_directory_service_directory_id = "d-777777777" #TBD
aws_kmskey_id                      = ""
fsx_subnets                        = ["subnet-aaaaaaaaaaaaaaaa", "subnet-bbbbbbbbbbbbbbb"]
fsx_throughput_capacity            = "1024"
fsx_storage_capacity               = "400"
fsx_deployment_type                = "MULTI_AZ_1"
fsx_storage_type                   = "SSD"
app_instance_type                  = "t3.2xlarge"
domain                             = "d-777777777" #TBD
domain_iam_role_name               = ""
fsx_secret_id           = "/dependencies-prod-app1/adcred"
fsx_dns_ips             = ["10.104.64.2"]
fsx_domain_name         = "nswhealth.net"
fsx_alias = ["app1-aws-prod-fsx.nswhealth.net"]
ehealth_cidrs                      = ["10.206.112.0/20", "10.206.240.0/20", "10.222.208.0/22", "10.253.192.0/22", "10.206.0.0/18", "10.206.64.0/20", "10.206.96.0/22", "10.206.80.0/20", "10.222.192.0/22", "10.206.192.0/20", "10.206.128.0/18", "10.206.208.0/20", "10.206.224.0/22", "10.206.196.0/23", "10.21.0.0/16", "10.20.208.136/32", "10.20.208.137/32", "10.20.208.197/32", "10.20.208.198/32"]

# RDS values
environment_tag = "prod"
db_name_tag     = "sqldbaw-app1-prod-001"
db_name_tag_ro  = "repl-sqldbaw-app1-prod-001"
db_instance_tags = {
  DBType      = "RDS"
  Engine      = "sqlserver-ee"
  Version     = "13.00.5882.1.v1"
  event       = "cloudwatch_dashboard"
  Description = "Primary Instance"
}
db_instance_ro_tags = {
  DBType      = "RDS"
  Engine      = "sqlserver-ee"
  Version     = "13.00.5882.1.v1"
  Description = "Read Only Replica"
}
rds_instance_identifier     = "sqldbaw-app1-prod-001"
rds_instance_identifier_ro  = "repl-sqldbaw-app1-prod-001"
no_rds_identifier_prefix    = true
database_username           = "admin"
# vpc_id = already defined
database_port                   = "1433"
engine                          = "sqlserver-ee"
engine_version                  = "13.00.5882.1.v1"
instance_class                  = "db.r5.2xlarge"
allocated_storage               = 500
db_parameter_group_family       = "sqlserver-ee-13.0"
deploy_using_snapshot           = false
snapshot_id                     = ""
max_allocated_storage           = 0
storage_type                    = "gp2"
iops                            = 0
storage_encrypted               = true
kms_key_name                    = "alias/dependencies-prod-app1-rds"
license_model                   = "license-included"
multi_az                        = true
publicly_accessible             = false
deletion_protection             = false
auto_minor_version_upgrade      = false
allow_major_version_upgrade     = false
skip_final_snapshot             = true
apply_immediately               = false
maintenance_window              = "Sat:16:05-Sat:19:00"
enhanced_monitoring_interval    = 60
enabled_cloudwatch_logs_exports = []
backup_retention_period         = 7
backup_window                   = "15:00-16:00" //UTC Time - Daily 1am-2am AEST
db_parameter_group_parameters = [{
  name         = "max server memory (mb)"
  value        = "57344"
  apply_method = "immediate"
},
{
  name         = "max degree of parallelism"
  value        = "8"
  apply_method = "immediate"
},
{
  name         = "cost threshold for parallelism"
  value        = "50"
  apply_method = "immediate"
},
{
  name         = "optimize for ad hoc workloads"
  value        = "1"
  apply_method = "immediate"
},
{
  name         = "rds.force_ssl"
  value        = "1"
  apply_method = "pending-reboot"
}]

db_parameter_group_name = null
db_subnet_group_name    = null
# option_group_name                    = ""
db_subnet_group_subnet_ids           = ["subnet-aaaaaaaaaaaaaaaa", "subnet-bbbbbbbbbbbbbbb", "subnet-cccccccccccccccccc"]
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
create_timeout                        = "2h"
update_timeout                        = "2h"
delete_timeout                        = "2h"
# active_directory_id = null
domain_join_rds_iam_role     = "rds-directoryservice-access-role"
iam_role_rds_monitoring_name = null
timezone                     = "AUS Eastern Standard Time"
availability_zone            = null

eH_std_tags = {
  BillingCustomer     = "John Smith"
  CostCenter          = "000000"
  DemandID            = "RITM111111111"
  Environment         = "prod"
  OracleProjectCode   = "EH SD CAS BAU Rostering"
  OracleProjectTaskID = "07.5.5"
  ServiceOffering     = "Managed"
  DR                  = "Critical"
  Owner               = "ABC Stone"
  ServiceClass        = "Gold"
  ApplicationName     = "app1"
  Approver            = "John Smith"
  BusinessUnit        = "EH-SD-CAS"
  DR                  = "Critical"
}

# DB Option group values
engine_name              = "sqlserver-ee"
major_engine_version     = "13.00"
db_option_group_name     = "SQLNATIVEBACKUP-EE-13-00"
option_group_description = "Enable AWS RDS SQL backup to S3"
opt_name_tag             = "SQLNATIVEBACKUP-EE-13-00"


citrix_smc_account = "111111111111"
esb_port="4500"
#FSx Backup values
 fsx_backup_vault_name_prefix    = "FSx"
 fsx_backup_daily_retention      =  14
 fsx_backup_enabled              = true
 fsx_backup_daily_schedule       = "cron(0 9 ? * MON-FRI *)" 
 fsx_backup_start_window         = 60
 fsx_backup_completion_window    = 360
 fsx_backup_weekly_schedule      = "cron(0 9 ? * SUN *)" 
 fsx_backup_monthly_schedule     = "cron(0 9 ? * 7L *)"
 fsx_backup_weekly_retention     = 60
 fsx_backup_monthly_retention    = 365
