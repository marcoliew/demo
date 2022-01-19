locals {
  buildlist       = fileset("../../${var.type}", "*.yml")
  stagename       = { for stage in local.buildlist : stage => trimsuffix(stage, ".yml") }
  resource_prefix = lower("${var.lhd}-${var.environment}-${var.deployment_role}-${var.type}")
}

resource "aws_s3_bucket" "releases" {
  bucket = "${local.resource_prefix}-releases"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        # kms_master_key_id = var.kms_master_key_id
        sse_algorithm = var.sse_algorithm
      }
    }
  }
   versioning {
    enabled = true
  }

  logging {
    target_bucket =var.logging_bucket
    target_prefix = "${local.resource_prefix}-releases/"
  }
}

resource "aws_s3_bucket_public_access_block" "block_pub_access" {
  bucket                  = aws_s3_bucket.releases.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "releases" {
  bucket = aws_s3_bucket.releases.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "MYBUCKETPOLICY"
    Statement = [
      {
        Sid    = "DeployAllow"
        Effect = "Allow"
        Principal : {
          "AWS" : [
            aws_iam_role.codebuild_role.arn
          ]
        }
        Action = "s3:*"
        Resource : aws_s3_bucket.releases.arn,
      },
      {
        "Sid" : "AllowSSLRequestsOnly",
        "Action" : "s3:*",
        "Effect" : "Deny",
        "Resource" : [
          aws_s3_bucket.releases.arn,
          "${aws_s3_bucket.releases.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        },
        "Principal" : "*"
      }
    ]
  })
}

#Create CodeBuild Jobs
resource "aws_codebuild_project" "codebuild" {
  for_each      = local.stagename
  name          = "${each.value}-${local.resource_prefix}"
  description   = "${var.lhd} ${each.value} CodeBuild Project"
  build_timeout = var.build_timeout
  service_role  = aws_iam_role.codebuild_role.arn

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = var.docker_build_image
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "Environment"
      value = var.environment
    }
    environment_variable {
      name  = "deployment_role"
      value = var.deployment_role
    }
    environment_variable {
      name  = "Type"
      value = var.type
    }
    environment_variable {
      name  = "lhd"
      value = var.lhd
    }
    environment_variable {
      name  = "codebuild_security_group"
      value = var.codebuild_security_group
    }
    environment_variable {
      name  = "app"
      value = var.app
    }

  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "${var.type}/${each.value}.yml"
  }
  secondary_sources {
    type                = "GITHUB_ENTERPRISE"
    location            = var.secondary_github_repository_url
    report_build_status = true
    source_identifier   = "eHealthModuleIntegration"
  }

  artifacts {
    type = "CODEPIPELINE"
  }
}


#Create IAM Resources
resource "aws_iam_role" "codebuild_role" {
  name = "${local.resource_prefix}-codebuild-role"

  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Principal" = {
          "Service" = [
            "codebuild.amazonaws.com",
            "codepipeline.amazonaws.com"
          ]
        },
        "Action" = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "codebuild_policy" {
  name        = "${local.resource_prefix}-codebuild-policy"
  path        = "/service-role/"
  description = "Policy used in trust relationship with CodeBuild"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Resource" : [
          "*"
        ],
        "Action" : [
          "autoscaling:*",
          "codebuild:*",
          "codepipeline:*",
          "ec2:*",
          "elasticloadbalancing:*",
          "iam:*",
          "logs:*",
          "rds:*",
          "secretsmanager:*",
          "kms:*",
          "route53:*",
          "s3:*",
          "fsx:*",
          "ds:*",
          "dynamodb:*",
          "events:*",
          "ssm:*",
          "acm:*",
          "sns:*",
          "backup:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "codebuild_policy_attachment" {
  name       = "codebuild-policy-attachment"
  policy_arn = aws_iam_policy.codebuild_policy.arn
  roles      = [aws_iam_role.codebuild_role.id]
}

resource "aws_codepipeline" "project" {
  name     = "${local.resource_prefix}-pipeline"
  role_arn = aws_iam_role.codebuild_role.arn

  artifact_store {
    location = aws_s3_bucket.releases.id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "TfTemplate"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        S3Bucket             = var.source_s3_bucket
        S3ObjectKey          = "${var.lhd}-${var.environment}-${var.app}.zip"
        PollForSourceChanges = var.poll_changes
      }
    }
  }

  dynamic "stage" {
    for_each = local.stagename
    content {
      name = stage.value
      action {
        name            = "${stage.value}-${var.lhd}"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["SourceArtifact"]
        version         = "1"
        run_order       = "1"
        configuration = {
          ProjectName = "${stage.value}-${local.resource_prefix}"
        }
      }
    }
  }
}