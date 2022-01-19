locals {
  resource_prefix = lower("${var.lhd}-${var.environment}-${var.app}-${var.instancerole}")
}

data "aws_ami" "windows" {
  owners      = ["self"]
  most_recent = "true"
  filter {
    name   = "name"
    values = ["${var.environment}-${var.app}-web-AMI-*"] #["poc-app1-web-AMI-*"] #["${var.instancerole}-*"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_acm_certificate" "web-cert" {
  domain = "*.nswhealth.net"
  #types    = ["Imported"]
  #statuses = ["ISSUED"]
  #most_recent = true
}


resource "aws_autoscaling_group" "asg" {
  name             = "${local.resource_prefix}-ASG" #"${var.app}-${var.instancerole}-${var.environment}-ASG"
  max_size         = var.max_size
  min_size         = var.min_size
  desired_capacity = var.desired_size
  #instance_type             = var.instance_type
  wait_for_capacity_timeout = 0
  #wait_for_elb_capacity


  health_check_grace_period = var.health_check_grace_period
  health_check_type         = var.health_check_type

  force_delete         = var.force_delete
  launch_configuration = aws_launch_configuration.lc.name
  vpc_zone_identifier  = var.subnet_list

  termination_policies = var.termination_policies

  target_group_arns = [aws_lb_target_group.web_ssl.arn,aws_lb_target_group.web_esb.arn]
  #load_balancers            = [aws_lb.alb.name]

  tag {
    key                 = "name"
    value               = "${local.resource_prefix}-ASG"
    propagate_at_launch = false
  }

  tag {
    key                 = "environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "lhd"
    value               = var.lhd
    propagate_at_launch = true
  }

  tag {
    key                 = "app"
    value               = var.app
    propagate_at_launch = true
  }

  timeouts {
    delete = var.timeouts #"15m"
  }

  tag {
    key                 = "event"
    value               = "cloudwatch_dashboard"
    propagate_at_launch = true
  }

  tag {
    key                 = "artifactBucket"
    value               = "${var.environment}-dependencies-${var.app}-artifacts-bucket" #train-dependencies-app1-artifacts-bucket
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "lc" {
  name_prefix          = "${local.resource_prefix}-LC"
  image_id             = data.aws_ami.windows.id
  instance_type        = var.instance_type
  iam_instance_profile = var.ec2_instance_role
  user_data            = base64encode(file("../../APP1scripts/${var.userdata_filename}.ps1"))
#   user_data = "${base64encode(<<EOF
# <powershell>
# aws s3 cp s3://dependencies-train-app1-userdata/userdata_web.ps1 c:/temp/app1/userdata_web.ps1
# ."c:/temp/app1/userdata_web.ps1"
# </powershell>
# <persist>true</persist>
# EOF
# )}"

  security_groups      = var.ec2_security_groups
  #key_name             = var.key_name
  # enable_monitoring
  lifecycle {
    create_before_destroy = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = "150"
    delete_on_termination = true
    encrypted             = true
  }
}


resource "aws_lb" "nlb" {
  load_balancer_type               = "network"
  name                             = "${local.resource_prefix}-NLB"
  enable_cross_zone_load_balancing = "true"
  enable_deletion_protection       = "true"
  subnets                          = length(var.nlb_subnet_mapping) > 0 ? null : var.subnet_list
  internal                         = "true"

  tags = merge(var.eH_std_tags,
     {
       Name = "${local.resource_prefix}-NLB"
     }
  )
  access_logs {
    bucket  = var.elb_logging_bucket
    prefix  = "${local.resource_prefix}-NLB"
    enabled = true
  }

  dynamic "subnet_mapping" {
    for_each = var.nlb_subnet_mapping
    content {
      subnet_id            = subnet_mapping.value.subnet
      private_ipv4_address = subnet_mapping.value.ip
    }
  }
}


resource "aws_lb_listener" "listener_TCP" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = var.esb_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_esb.arn
  }
}

resource "aws_lb_target_group" "web_esb" {
  name        = "${local.resource_prefix}-tg-${var.esb_port}"
  port        = var.esb_port
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id
  health_check {
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }

}



resource "aws_lb" "alb" {
  name               = "${local.resource_prefix}-ALB"
  internal           = true
  load_balancer_type = "application"
  security_groups    = var.alb_security_groups
  subnets            = var.subnet_list

  enable_deletion_protection = true

  tags = {
    Environment = var.environment
    Name        = "${local.resource_prefix}-ALB"
  }
   access_logs {
    bucket  = var.elb_logging_bucket
    prefix  = "${local.resource_prefix}-ALB"
    enabled = true
  }
}

resource "aws_lb_listener" "listener_https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.web-cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_ssl.arn
  }
}

resource "aws_lb_target_group" "web_ssl" {
  name        = "${local.resource_prefix}-tg"
  port        = 443
  protocol    = "HTTPS"
  target_type = "instance"
  vpc_id      = var.vpc_id
  health_check {
    path = var.lb_healthcheck_path #"/" #"/titanium/web/admin/titaniummanager.html"
    #port                = 443
    protocol            = "HTTPS"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200" # has to be HTTP 200 or fails
  }

}

resource "aws_autoscaling_lifecycle_hook" "hook_ec2_terminating" {
  name                    = "LCH_EC2_INSTANCE_TERMINATING"
  autoscaling_group_name  = aws_autoscaling_group.asg.name
  default_result          = "CONTINUE"
  heartbeat_timeout       = 2000
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  notification_target_arn = var.sns_topic_default_notification_arn
  role_arn                = var.asg_hook_sns_role_arn
}



resource "aws_cloudwatch_event_rule" "event_rule_asg_termination" {
  name        = "${local.resource_prefix}-event-rule-asg-termination"
  description = "This will be trigger when a Web server taken off ASG."
  event_pattern = jsonencode(
    {
      source      = ["aws.autoscaling"],
      detail-type = ["EC2 Instance-terminate Lifecycle Action"],
      detail = {
        AutoScalingGroupName = [aws_autoscaling_group.asg.name]
      }
    }
  )


  /*   event_pattern = <<EOF
{
    "detail-type": [
      "EC2 Instance-terminate Lifecycle Action"
    ],
    "source": [
      "aws.autoscaling"
    ],
    "detail": {
      "AutoScalingGroupName": [
        ${aws_autoscaling_group.asg.name}
      ]
    }
}
EOF */
}


resource "aws_cloudwatch_event_target" "event_rule_target_ssm_doc" {
  rule      = aws_cloudwatch_event_rule.event_rule_asg_termination.name
  target_id = "${local.resource_prefix}-ADClean-ssm-automation-target"
  arn       = replace(aws_ssm_document.ec2_terminaing_doc.arn, "document/", "automation-definition/") #aws_ssm_document.ec2_terminaing_doc.arn #done
  role_arn  = var.event_run_ssm_doc_role_arn                                                          #aws_iam_role.event_ADObject_clean_role.arn
  input_transformer {
    input_paths = {
      instanceid = "$.detail.EC2InstanceId"
    }

    input_template = <<EOF
  {
    "InstanceId": <instanceid>
  }
  EOF
    #input_template = "\"InstanceId\":[<instanceid>]"
  }
}
/* 

resource "aws_iam_role" "event_ADObject_clean_role" {
  name = "${local.resource_prefix}-event-ADclean-run-ssm-doc-role"
  #tags = var.eH_std_tags
  description = "Role assumed by event target to run ssm doc"

  assume_role_policy = jsonencode({ 
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
  })
  
  inline_policy { #tbd
    name = "Start-SSM-Automation-Policy"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "ssm:StartAutomationExecution"
          ],
          "Resource" : aws_ssm_document.ec2_terminaing_doc.arn,  #done  #"arn:aws:ssm:ap-southeast-2:497427545767:automation-definition/poc-app1-cf-ADObject-clean-document-PlvBWwwQeGfR:$DEFAULT", # to be update
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
          "Resource" : aws_iam_role.ssm_doc_asg_lifecycle_role.arn, # to be update
          "Effect" : "Allow"
        }
      ]
    })
  }

}


resource "aws_iam_role" "ssm_doc_asg_lifecycle_role" {
  name = "${local.resource_prefix}-ssm-doc-asg-lifecycle-role"
  description = "Role assumed by ssm doc to complete ASG lifecycle hook"
  #tags = var.eH_std_tags

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ssm.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
}
  EOF
  inline_policy { #tbd
    name = "SSM-Automation-Permission-to-CompleteLifecycle-Policy"

    policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
            "Action": [
                "autoscaling:CompleteLifecycleAction"
            ],
            "Resource": aws_autoscaling_group.asg.arn #"arn:aws:autoscaling:ap-southeast-2:497427545767:autoScalingGroup:*:autoScalingGroupName/poc-asg-web",
            "Effect": "Allow"
        }
    ]
    })
  }

  inline_policy {
    name = "SSM-Automation-Policy"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
            "Action": [
                "ec2:CreateImage",
                "ec2:DescribeImages",
                "ssm:DescribeInstanceInformation",
                "ssm:ListCommands",
                "ssm:ListCommandInvocations"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "ssm:SendCommand"
            ],
            "Resource": "arn:aws:ssm:ap-southeast-2::document/AWS-RunPowerShellScript",
            "Effect": "Allow"
        },
        {
            "Action": [
                "ssm:SendCommand"
            ],
            "Resource": "arn:aws:ec2:*:*:instance/*",
            "Effect": "Allow"
        }
      ]
    })
  }

}
 */



resource "aws_ssm_document" "ec2_terminaing_doc" { #to update role name below
  name          = "${local.resource_prefix}-ADObject-clean-doc"
  document_type = "Automation"

  content = <<DOC
{
  "schemaVersion": "0.3",
  "description": "This document will disjoin instances From an Active Directory, send a signal to the LifeCycleHook to terminate the instance",
  "assumeRole": "{{AutomationAssumeRole}}",
  "parameters": {
    "AutomationAssumeRole": {
      "default": "${var.ssm_doc_asg_lifecycle_role_arn}",
      "description": "(Required) The ARN of the role that allows Automation to perform the actions on your behalf.",
      "type": "String"
    },
    "ASGName": {
      "default": "${aws_autoscaling_group.asg.name}}",
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
            "$ou = \"OU=Servers,OU=NSWH-Titanium86-NonProd-AWS-TEST,OU=Self-Managed,OU=Cloud,OU=State Resources - Automation,DC=nswhealth,DC=net\"",
            "$PartOfDomain = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain",
            "if($PartOfDomain -eq $true){",
            "$secrets_manager_secret_id = \"/dependencies-train-app1/adcred\"",
            "$secret_manager = Get-SECSecretValue -SecretId $secrets_manager_secret_id",
            "$secret = $secret_manager.SecretString | ConvertFrom-Json",
            "$username = $secret.admuser",
            "$password = $secret.admpwd | ConvertTo-SecureString -AsPlainText -Force",
            "$credential = New-Object System.Management.Automation.PSCredential($username,$password)",
            "Write-Output \"Removing computer $name from the domain\"",
            "Get-QADComputer -Identity $name -Credential $credential -service ActiveRolesMMC.nswhealth.net -Proxy | Remove-QADObject -Credential $credential -service ActiveRolesMMC.nswhealth.net -Proxy",
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

