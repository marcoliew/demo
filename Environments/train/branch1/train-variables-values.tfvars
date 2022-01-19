
app                    = "app1"
environment            = "train"
lhd                    = "branch1"
envtag                 = "nonp"
vpc_id                 = "vpc-00000000000000000"
s3_tfstate_bucket      = "train-branch1-app1-tfstate-bucket"
artifacts_bucket       = "train-branch1-app1-artifacts-bucket"
dynamo_db_table_name   = "train-branch1-app1-lockDynamo"
git_source_code_bucket = "train-dependencies-git-health-code-app1"
account_id             = "222222222222"
github_pat             = "/dependencies-train-app1/PAT"
vpc_subnets            = ["subnet-3333333333333333", "subnet-3333333333333333", "subnet-3333333333333333"]
vpc_subnet1            = "subnet-3333333333333333" #ap-southeast-2a
vpc_subnet2            = "subnet-3333333333333333" #ap-southeast-2b
vpc_subnet3            = "subnet-3333333333333333" #ap-southeast-2c
subnets_cidr           = ["10.104.125.0/25", "10.104.124.128/25", "10.104.125.128/25"]
s3_buckets_list        = []
webhook_filter_branch  = "Non-prod"
iam_policy_arn = [
  "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
  "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
  "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess"
]

eH_std_tags = {
  BillingCustomer     = "John Smith"
  CostCenter          = "000000"
  DemandID            = "RITM111111111"
  Environment         = "train"
  OracleProjectCode   = "EH SD CAS BAU Rostering"
  OracleProjectTaskID = "07.5.5"
  ServiceOffering     = "Managed"
  DR                  = "Critical"
  Owner               = "Dummy"
  ServiceClass        = "Gold"
  ApplicationName     = "app1"
  Approver            = "John Smith"
  BusinessUnit        = "EH-SD-CAS"
  DR                  = "Critical"
}

asg_max_size             = 1
asg_min_size             = 0
asg_desired_size         = 1
asg_check_period         = "600"
asg_check_type           = "EC2"
asg_instance_type        = "t2.xlarge"
asg_force_delete         = true
asg_termination_policies = ["OldestInstance"]
asg_timeouts             = "15m"
esb_port                 = "4501"

nlb_subnet_mapping = [
  {
    subnet = "subnet-3333333333333333"
    ip = "10.104.125.4"
  },
  {
    subnet = "subnet-3333333333333333"
    ip = "10.104.124.132"
  },
  {
    subnet = "subnet-3333333333333333"
    ip = "10.104.125.132"
  }
]

fsx_storage_type                   = "SSD"
fsx_deployment_type                = "MULTI_AZ_1"
fsx_throughput_capacity            = "1024"
fsx_storage_capacity               = "400"
fsx_secret_id                      = "/dependencies-train-app1/adcred"
fsx_domain_name                    = "nswhealth.net"
fsx_subnets                        = ["subnet-3333333333333333", "subnet-3333333333333333"]
fsx_subnets_preferred              = "subnet-3333333333333333"
fsx_dns_ips                        = ["10.104.64.2"]
fsx_admins_group                   = "L-NSWH-Oral Health branch1 File Access"

