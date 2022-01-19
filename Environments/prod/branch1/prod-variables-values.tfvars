
app                    = "app1"
environment            = "prod"
lhd                    = "branch1"
envtag                 = "prod"
vpc_id                 = "vpc-00000000000000000"
s3_tfstate_bucket      = "prod-branch1-app1-tfstate-bucket"
artifacts_bucket       = "prod-branch1-app1-artifacts-bucket"
dynamo_db_table_name   = "prod-branch1-app1-lockDynamo"
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

eH_std_tags = {
  BillingCustomer     = "John Smith"
  CostCenter          = "000000"
  DemandID            = "RITM111111111"
  Environment         = "prod"
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
asg_instance_type        = "t3.xlarge"
asg_force_delete         = true
asg_termination_policies = ["OldestInstance"]
asg_timeouts             = "15m"

esb_port                 = "4500"
nlb_subnet_mapping = [  #TBD
  {
    subnet = "subnet-aaaaaaaaaaaaaaaa"
    ip = "10.137.64.7"
  },
  {
    subnet = "subnet-bbbbbbbbbbbbbbb"
    ip = "10.137.64.133"
  },
  {
    subnet = "subnet-cccccccccccccccccc"
    ip = "10.137.65.5"
  }
]

aws_directory_service_directory_id = "d-777777777" #TBD
aws_kmskey_id                      = ""
fsx_subnets                        = ["subnet-aaaaaaaaaaaaaaaa", "subnet-bbbbbbbbbbbbbbb"]
fsx_subnets_preferred                        = "subnet-aaaaaaaaaaaaaaaa"
fsx_throughput_capacity            = "1024"
fsx_storage_capacity               = "400"
fsx_deployment_type                = "MULTI_AZ_1"
fsx_storage_type                   = "SSD"
app_instance_type                  = "t3.2xlarge"
domain                             = "d-777777777"
domain_iam_role_name               = ""
fsx_secret_id           = "/dependencies-prod-app1/adcred"
fsx_dns_ips             = ["10.104.64.2"]
fsx_domain_name         = "nswhealth.net"
fsx_admins_group = "L-NSWH-Oral Health branch1 File Access"
ehealth_cidrs                      = ["10.206.112.0/20", "10.206.240.0/20", "10.222.208.0/22", "10.253.192.0/22", "10.206.0.0/18", "10.206.64.0/20", "10.206.96.0/22", "10.206.80.0/20", "10.222.192.0/22", "10.206.192.0/20", "10.206.128.0/18", "10.206.208.0/20", "10.206.224.0/22", "10.206.196.0/23", "10.21.0.0/16", "10.20.208.136/32", "10.20.208.137/32", "10.20.208.197/32", "10.20.208.198/32"]
