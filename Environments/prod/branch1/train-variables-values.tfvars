
app                    = "app1"
environment            = "prod"
lhd                    = "branch1"
envtag                 = "nonp"
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
<<<<<<< HEAD:Environments/prod/branch1/train-variables-values.tfvars
webhook_filter_branch  = "Production"
=======
webhook_filter_branch  = "Non-prod"
>>>>>>> b07c874f27f6b912c2e2cb57ab046b030cab8b15:Environments/train/branch1/train-variables-values.tfvars
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
asg_instance_type        = "t2.xlarge"
asg_force_delete         = true
asg_termination_policies = ["OldestInstance"]
asg_timeouts             = "15m"
esb_port                 = "4501"

nlb_subnet_mapping = [  #TBD
  {
<<<<<<< HEAD:Environments/prod/branch1/train-variables-values.tfvars
    subnet = "subnet-aaaaaaaaaaaaaaaa"
    ip = "10.104.125.125"
  },
  {
    subnet = "subnet-bbbbbbbbbbbbbbb"
    ip = "10.104.124.253"
  },
  {
    subnet = "subnet-cccccccccccccccccc"
    ip = "10.104.125.253"
=======
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
>>>>>>> b07c874f27f6b912c2e2cb57ab046b030cab8b15:Environments/train/branch1/train-variables-values.tfvars
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

