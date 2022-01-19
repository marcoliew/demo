# ----------------------------------------------------------------------------------------------------
# Security Groups for various resources
# ----------------------------------------------------------------------------------------------------
module "security_group_packer" {
  source                 = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-security-group.git?ref=v2.0.0"
  environment_tag        = var.environment
  name                   = "${local.resource_prefix}-Packer-Codebuild"
  name_tag               = "${local.resource_prefix}-Packer-Codebuild"
  description            = "Security Group To Allow Access To Fsx share drive"
  revoke_rules_on_delete = false
  vpc_id                 = var.vpc_id
  optional_tags          = var.eH_std_tags

  ingress_rules_base = [
    {
      description = "Allow WinRM between Codebuild and Packer instance",
      from_port   = 5986,
      to_port     = 5986,
      protocol    = "TCP",
      self        = true
    },
  ]
  egress_rules_base = [
    {
      description = "SSM Session Manager from VPC Subnet CIDR",
      from_port   = 0,
      to_port     = 0,
      protocol    = "-1",
      cidr_blocks = var.subnets_cidr
    },
    {
      description     = "out-https-cidr-allprivate-cloud-private-endpoints",
      from_port       = "443",
      to_port         = "443",
      protocol        = "tcp",
      cidr_blocks = ["10.0.0.0/8"]
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.aws_endpoints.id, data.aws_ec2_managed_prefix_list.s3_endpoint.id]
    }
  ]
}
module "security_group_Fsx" {
  source                 = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-security-group.git?ref=v2.0.0"
  environment_tag        = var.environment
  name                   = "${local.resource_prefix}-Fsx-sg"
  name_tag               = "${local.resource_prefix}-Fsx-sg"
  description            = "Security Group To Allow Access To Fsx share drive"
  revoke_rules_on_delete = false
  vpc_id                 = var.vpc_id

  ingress_rules_base = [
    {
      description     = "SMB",
      from_port       = 445,
      to_port         = 445,
      protocol        = "TCP",
      cidr_blocks     = ["10.0.0.0/8"]
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.jumphosts.id, aws_ec2_managed_prefix_list.citrix-smc.id]
    },
  ]
  egress_rules_base = [

  ]

}

module "security_group_Alb" {
  source                 = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-security-group.git?ref=v2.0.0"
  environment_tag        = var.environment
  name                   = "${local.resource_prefix}-Alb-sg"
  name_tag               = "${local.resource_prefix}-Alb-sg"
  description            = "Security Group To Allow Access To Application Load Balancer"
  revoke_rules_on_delete = false
  vpc_id                 = var.vpc_id

  ingress_rules_base = [
    {
      description     = "HTTP",
      from_port       = 80,
      to_port         = 80,
      protocol        = "TCP",
      cidr_blocks     = var.subnets_cidr
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.jumphosts.id, aws_ec2_managed_prefix_list.citrix-smc.id]
      #security_groups = [module.security_group_alb.security_group_id]
    },
    {
      description     = "HTTPS",
      from_port       = 443,
      to_port         = 443,
      protocol        = "TCP",
      cidr_blocks     = var.subnets_cidr
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.jumphosts.id, aws_ec2_managed_prefix_list.citrix-smc.id]
      #security_groups = [module.security_group_alb.security_group_id]
    }
  ]
  egress_rules_base = [
  ]

}


module "security_group_ssrs" {
  source                 = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-security-group.git?ref=v2.0.0"
  environment_tag        = var.environment
  name                   = "${local.resource_prefix}-ssrs-sg"
  name_tag               = "${local.resource_prefix}-ssrs-sg"
  description            = "Security Group To Allow Access To Application Load Balancer"
  revoke_rules_on_delete = false
  vpc_id                 = var.vpc_id

  ingress_rules_base = [
    {
      description     = "HTTP",
      from_port       = 80,
      to_port         = 80,
      protocol        = "TCP",
      cidr_blocks     = ["10.0.0.0/8"]
      prefix_list_ids = [aws_ec2_managed_prefix_list.citrix-smc.id]
      security_groups = [module.security_group_Alb.security_group_id]
    },
    {
      description     = "RDP",
      from_port       = 3389,
      to_port         = 3389,
      protocol        = "TCP",
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.jumphosts.id]
      self            = true
    },
    {
      description = "Reporting Services accessiility to LHDs",
      from_port   = 443,
      to_port     = 443,
      protocol    = "TCP",
      cidr_blocks = ["10.0.0.0/8"]
    },
    {
      description     = "SQL Server ",
      from_port       = 1433,
      to_port         = 1433,
      protocol        = "TCP",
      cidr_blocks     = var.subnets_cidr
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.jumphosts.id, aws_ec2_managed_prefix_list.citrix-smc.id]
      self            = true
    },
    {
      description     = "HTTPS",
      from_port       = 443,
      to_port         = 443,
      protocol        = "TCP",
      cidr_blocks     = var.subnets_cidr
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.jumphosts.id, aws_ec2_managed_prefix_list.citrix-smc.id]
      security_groups = [module.security_group_Alb.security_group_id]
    }
  ]
  egress_rules_base = [
        {
      description     = "out-https-cidr-allprivate-cloud-private-endpoints",
      from_port       = "443",
      to_port         = "443",
      protocol        = "tcp",
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.aws_endpoints.id, data.aws_ec2_managed_prefix_list.s3_endpoint.id]
    },
    {
      description     = "db entry point - sg custom",
      from_port       = 1433,
      to_port         = 1433,
      protocol        = "tcp",
      cidr_blocks     = var.subnets_cidr
    },
    {
      description = "RDS to Managed AD - sg custom",
      from_port   = 0,
      to_port     = 0,
      protocol    = "-1",
      cidr_blocks = ["10.0.0.0/8"]
    },
    
  ]

}


module "security_group_Ec2" {
  source                 = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-security-group.git?ref=v2.0.0"
  environment_tag        = var.environment
  name                   = "${local.resource_prefix}-EC2-sg"
  name_tag               = "${local.resource_prefix}-EC2-sg"
  description            = "Security Group To Allow Access To Application Load Balancer"
  revoke_rules_on_delete = false
  vpc_id                 = var.vpc_id

  ingress_rules_base = [
    {
      description     = "HTTP",
      from_port       = 80,
      to_port         = 80,
      protocol        = "TCP",
      cidr_blocks     = var.subnets_cidr
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.jumphosts.id, aws_ec2_managed_prefix_list.citrix-smc.id]
      security_groups = [module.security_group_Alb.security_group_id]
    },
    {
      description     = "RDP",
      from_port       = 3389,
      to_port         = 3389,
      protocol        = "TCP",
      cidr_blocks     = ["10.104.86.167/32"]
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.jumphosts.id]
      self            = true
    },
    {
      description     = "HTTPS",
      from_port       = 443,
      to_port         = 443,
      protocol        = "TCP",
      cidr_blocks     = var.subnets_cidr
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.jumphosts.id, aws_ec2_managed_prefix_list.citrix-smc.id]
      security_groups = [module.security_group_Alb.security_group_id]
    },
    {
      description     = "db entry point - sg custom",
      from_port       = 19497,
      to_port         = 19497,
      protocol        = "tcp",
      cidr_blocks     = ["10.20.111.8/32","10.20.111.9/32","10.20.111.20/32","10.20.111.21/32","10.20.111.22/32","10.22.111.132/32","10.22.111.133/32","10.22.111.134/32","10.141.11.52/32","10.141.11.53/32","10.141.11.54/32"]
    },
    {
      description     = "db entry point - sg custom",
      from_port       = var.esb_port,
      to_port         = var.esb_port,
      protocol        = "tcp",
      cidr_blocks     = ["10.20.111.8/32","10.20.111.9/32","10.20.111.20/32","10.20.111.21/32","10.20.111.22/32","10.22.111.132/32","10.22.111.133/32","10.22.111.134/32","10.141.11.52/32","10.141.11.53/32","10.141.11.54/32"]
    },
    {
      description     = "db entry point - sg custom",
      from_port       = var.esb_port,
      to_port         = var.esb_port,
      protocol        = "tcp",
      cidr_blocks     = var.subnets_cidr
    }
  ]
  egress_rules_base = [
    {
      description = "All traffic to anywhere",
      from_port   = 443,
      to_port     = 443,
      protocol    = "TCP",
      cidr_blocks     = var.subnets_cidr
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.aws_endpoints.id, data.aws_ec2_managed_prefix_list.s3_endpoint.id]
    },
    {
      description     = "db entry point - sg custom",
      from_port       = 1433,
      to_port         = 1433,
      protocol        = "tcp",
      cidr_blocks     = var.subnets_cidr
    },
    {
      description     = "db entry point - sg custom",
      from_port       = 19497,
      to_port         = 19497,
      protocol        = "tcp",
      cidr_blocks     = ["10.20.111.8/32","10.20.111.9/32","10.20.111.20/32","10.20.111.21/32","10.20.111.22/32","10.22.111.132/32","10.22.111.133/32","10.22.111.134/32","10.141.11.52/32","10.141.11.53/32","10.141.11.54/32"]
    },
    {
      description     = "db entry point - sg custom",
      from_port       = var.esb_port,
      to_port         = var.esb_port,
      protocol        = "tcp",
      cidr_blocks     = ["10.20.111.8/32","10.20.111.9/32","10.20.111.20/32","10.20.111.21/32","10.20.111.22/32","10.22.111.132/32","10.22.111.133/32","10.22.111.134/32","10.141.11.52/32","10.141.11.53/32","10.141.11.54/32"]
    },
    {
      description     = "db entry point - sg custom",
      from_port       = 21,
      to_port         = 21,
      protocol        = "tcp",
      cidr_blocks     = ["10.141.1.72/32","10.33.70.15/32","10.33.70.14/32","10.144.30.88/32"]
    },
    {
      description     = "db entry point - sg custom",
      from_port       = 25,
      to_port         = 25,
      protocol        = "tcp",
      cidr_blocks     = ["10.20.127.75/32","10.22.127.75/32","10.140.52.49/32","10.144.52.49/32"]
    },
    {
      description     = "ARS endpoint - sg custom",
      from_port       = 15172,
      to_port         = 15172,
      protocol        = "tcp",
      cidr_blocks     = ["10.144.49.108/32"]
    },
    {
      description     = "db entry point - sg custom",
      from_port       = 445,
      to_port         = 445,
      protocol        = "tcp",
      cidr_blocks     = ["10.141.67.195/32","10.141.67.196/32","10.141.67.118/32","10.141.67.119/32","10.141.67.169/32","10.141.67.170/32","10.141.67.171/32","10.141.67.172/32"]
    },
    {
      description     = "db entry point - sg custom",
      from_port       = 80,
      to_port         = 80,
      protocol        = "tcp",
      cidr_blocks     = var.subnets_cidr
    }
  ]

}



module "security_group_RDS" {
  source                 = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-security-group.git?ref=v2.0.0"
  environment_tag        = var.environment
  name                   = "${local.resource_prefix}-RDS-sg"
  name_tag               = "${local.resource_prefix}-RDS-sg"
  description            = "Security Group To Allow Access To RDS from citrix"
  revoke_rules_on_delete = false
  vpc_id                 = var.vpc_id
  optional_tags          = var.eH_std_tags
  ingress_rules_base = [
    {
      description     = "db entry point - sg custom",
      from_port       = 1433,
      to_port         = 1433,
      protocol        = "tcp",
      security_groups = [module.security_group_ssrs.security_group_id,module.security_group_Ec2.security_group_id]
      prefix_list_ids = [aws_ec2_managed_prefix_list.citrix-smc.id]
    },
    {
      description = "DB endpoint to LHDs",
      from_port   = 1433,
      to_port     = 1433,
      protocol    = "TCP",
      cidr_blocks = ["10.0.0.0/8"]
    },
  ]
  egress_rules_base = [
    {
      description     = "db entry point - sg custom",
      from_port       = 1433,
      to_port         = 1433,
      protocol        = "tcp",
      self = true
    },
    {
      description = "RDS to Managed AD - sg custom",
      from_port   = 0,
      to_port     = 0,
      protocol    = "-1",
      cidr_blocks = ["10.0.0.0/8"]
    },
  ]
}