# # ----------------------------------------------------------------------------------------------------
# # Create IAM Roles
# # ----------------------------------------------------------------------------------------------------
resource "aws_iam_role" "ec2_app1_role" {
  name = "${local.resource_prefix}-ec2-role"
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
}

resource "aws_iam_role_policy_attachment" "role-policy-attachment" {
  role       = aws_iam_role.ec2_app1_role.name
  count      = length(var.iam_policy_arn)
  policy_arn = var.iam_policy_arn[count.index]
}

resource "aws_iam_policy" "ec2-tagging-policy" {
  name        = "${local.resource_prefix}-ec2-tagging-policy"
  path        = "/"
  description = "Allowing ec2 to update license status by tagging"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Tagging",
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteTags",
          "ec2:DescribeInstances",
          "ec2:CreateTags"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "S3Access",
        "Effect" : "Allow",
        "Action" : [
          "s3:*"
        ],
        "Resource" : "arn:aws:s3:::${var.environment}-dependencies-app1-artifacts-bucket/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:PutParameter"
        ],
        "Resource" : [
          "arn:aws:ssm:ap-southeast-2:${var.account_id}:parameter/${var.environment}/*",
          "arn:aws:ssm:ap-southeast-2:${var.account_id}:parameter/app1-${var.environment}/*",
          "arn:aws:ssm:ap-southeast-2:${var.account_id}:parameter/dependencies-${var.environment}/*",
          "arn:aws:ssm:ap-southeast-2:${var.account_id}:parameter/dependencies-app1-${var.environment}/*",
          "arn:aws:ssm:ap-southeast-2:${var.account_id}:parameter/dependencies-${var.environment}-app1/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2-tagging-policy-attachment" {
  role       = aws_iam_role.ec2_app1_role.name
  policy_arn = aws_iam_policy.ec2-tagging-policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.resource_prefix}-ec2-profile"
  role = aws_iam_role.ec2_app1_role.name
}

resource "aws_iam_policy" "sql_s3_backup_policy" {
  name        = "${local.resource_prefix}-sql-s3-backup-policy"
  path        = "/"
  description = "SQL Native S3 Backup Policy for ${var.environment} environment"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        "Resource" : [
          aws_s3_bucket.app1_sqlbackup.arn
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload"
        ],
        "Resource" : [
          "${aws_s3_bucket.app1_sqlbackup.arn}/*"
        ]
      }
    ]
    }
  )
}
resource "aws_iam_role" "RDS_app1_role" {
  name = "${local.resource_prefix}-RDS-role"

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
  tags               = var.eH_std_tags
}

resource "aws_iam_role_policy_attachment" "sql_s3_backup_policy_attachment" {
  role       = aws_iam_role.RDS_app1_role.name
  policy_arn = aws_iam_policy.sql_s3_backup_policy.arn
}

resource "aws_iam_role_policy_attachment" "sql_ds_policy_attachment" {
  role       = aws_iam_role.RDS_app1_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSDirectoryServiceAccess"
}

# IAM roles for ASG lifecyc hook, output for consuming

resource "aws_iam_role" "event_run_ssm_doc_role" {
  name = "${local.resource_prefix}-event-run-ssm-doc-role"
  #tags = var.eH_std_tags
  description = "Role assumed by event target to run ssm doc"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "events.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
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
          "Resource" : "*",
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
          "Resource" : "*",
          "Effect" : "Allow"
        }
      ]
    })
  }

}


resource "aws_iam_role" "ssm_doc_asg_lifecycle_role" {
  name        = "${local.resource_prefix}-ssm-doc-asg-lifecycle-role"
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
  inline_policy {
    name = "SSM-Automation-Permission-to-CompleteLifecycle-Policy"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "autoscaling:CompleteLifecycleAction"
          ],
          "Resource" : "*"
          "Effect" : "Allow"
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
          "Action" : [
            "ec2:CreateImage",
            "ec2:DescribeImages",
            "ssm:DescribeInstanceInformation",
            "ssm:ListCommands",
            "ssm:ListCommandInvocations"
          ],
          "Resource" : "*",
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "ssm:SendCommand"
          ],
          "Resource" : "arn:aws:ssm:ap-southeast-2::document/AWS-RunPowerShellScript",
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "ssm:SendCommand"
          ],
          "Resource" : "arn:aws:ec2:*:*:instance/*",
          "Effect" : "Allow"
        }
      ]
    })
  }

}

resource "aws_iam_role" "asg_hook_sns_role" {
  name = "${local.resource_prefix}-asg-hook-sns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "autoscaling.amazonaws.com"
        }
      },
    ]
  })
  inline_policy {
    name = "asg-sns-policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "SNS",
          "Effect" : "Allow",
          "Action" : [
            "sns:Publish"
          ],
          "Resource" : "*"
        }
      ]
    })
  }
}

# resource "aws_iam_service_linked_role" "ec2autoscaling" {
#   aws_service_name = "autoscaling.amazonaws.com"
# }