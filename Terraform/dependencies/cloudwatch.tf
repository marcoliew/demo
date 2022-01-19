resource "aws_sns_topic" "cloudwatch_handling" {
  name = "${local.resource_prefix}-cloudwatch-dashboard"
}

resource "aws_iam_role_policy" "cloudwatch_handling" {
  name   = "${local.resource_prefix}-cloudwatch-dashboard"
  role   = aws_iam_role.cloudwatch_handling.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
        "Effect": "Allow",
        "Action": "cloudwatch:PutDashboard",
        "Resource": "arn:aws:cloudwatch::*:dashboard/*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "cloudwatch_handling" {
  name = "${local.resource_prefix}-cloudwatch-dashboard"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
    "arn:aws:iam::aws:policy/ResourceGroupsandTagEditorReadOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
  ]
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role" "lifecycle" {
  name               = "${local.resource_prefix}-lifecycle"
  assume_role_policy = data.aws_iam_policy_document.lifecycle.json
}

data "aws_iam_policy_document" "lifecycle" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "lifecycle_policy" {
  name   = "${local.resource_prefix}-lifecycle"
  role   = aws_iam_role.lifecycle.id
  policy = data.aws_iam_policy_document.lifecycle_policy.json
}

data "aws_iam_policy_document" "lifecycle_policy" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = ["arn:aws:sns:ap-southeast-2:${var.account_id}:*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["autoscaling:CompleteLifecycleAction"]
    resources = ["arn:aws:autoscaling:ap-southeast-2:${var.account_id}:autoScalingGroup:*:autoScalingGroupName/*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = ["*"]
  }
}

data "archive_file" "cloudwatch" {
  type        = "zip"
  source_file = "../../APP1scripts/cw_dashboard.py"
  output_path = "../../APP1scripts/cw_dashboard.zip"
}

resource "aws_lambda_function" "cloudwatch_handling" {
  filename         = data.archive_file.cloudwatch.output_path
  function_name    = "${local.resource_prefix}-cloudwatch-dashboard"
  role             = aws_iam_role.cloudwatch_handling.arn
  handler          = "cw_dashboard.lambda_handler"
  runtime          = "python3.8"
  timeout          = "15"
  source_code_hash = data.archive_file.cloudwatch.output_base64sha256
  description      = "Handles dashboard for EC2, RDS and loadbalance by filtering tag "
  environment {
    variables = {
      app = var.app
      env = var.environment
    }
  }
}

resource "aws_lambda_permission" "cloudwatch_handling" {
  depends_on    = [aws_lambda_function.cloudwatch_handling]
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudwatch_handling.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.cloudwatch_handling.arn
}

resource "aws_sns_topic_subscription" "cloudwatch_handling" {
  depends_on = [aws_lambda_permission.cloudwatch_handling]
  topic_arn  = aws_sns_topic.cloudwatch_handling.arn
  protocol   = "lambda"
  endpoint   = aws_lambda_function.cloudwatch_handling.arn
}

