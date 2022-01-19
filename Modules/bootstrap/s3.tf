# ----------------------------------------------------------------------------------
# Create S3 Logging bucket
# ----------------------------------------------------------------------------------

module "s3_logging" {
  source = "git::https://git.health.nsw.gov.au/ehnsw-terraform/module-aws-s3-bucket.git?ref=v2.0.1"

  environment_tag = var.env
  bucket          = "${var.app}-${var.envtag}-${var.lhd}-${var.env}-s3-logger"
  acl             = "log-delivery-write"
}

resource "aws_s3_bucket_policy" "logging" {
   bucket = module.s3_logging.id
   policy = jsonencode({
   "Version": "2012-10-17",
   "Statement": [
     {
       "Effect": "Allow",
       "Principal": {
         "AWS": data.aws_elb_service_account.main.arn
       },
       "Action": "s3:PutObject",
       "Resource": "${module.s3_logging.arn}/*"
     },
     {
       "Effect": "Allow",
       "Principal": {
         "Service": "delivery.logs.amazonaws.com"
       },
       "Action": "s3:PutObject",
       "Resource": "${module.s3_logging.arn}/*",
       "Condition": {
         "StringEquals": {
           "s3:x-amz-acl": "bucket-owner-full-control"
         }
       }
     },
     {
       "Effect": "Allow",
       "Principal": {
         "Service": "delivery.logs.amazonaws.com"
       },
       "Action": "s3:GetBucketAcl",
       "Resource": module.s3_logging.arn
     }
   ]
 })
 }


# ----------------------------------------------------------------------------------
# ALB Logging S3 Bucket
# -----------------------------------------------------------------------------------

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "this" {
  bucket_prefix = "${var.env}-${var.lhd}-elb-access-logging"
  acl           = "log-delivery-write"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
versioning {
    enabled = true
  }
  logging {
    target_bucket = module.s3_logging.id
    target_prefix = "${var.env}-${var.lhd}-elb-access-logging/"
  }
}

#SSL Force policy will conflict with Delivery logging
#Cannot use SSL force policy on this bucket
resource "aws_s3_bucket_policy" "this" {
   bucket = aws_s3_bucket.this.id
   policy = jsonencode({
   "Version": "2012-10-17",
   "Statement": [
     {
       "Effect": "Allow",
       "Principal": {
         "AWS": data.aws_elb_service_account.main.arn
       },
       "Action": "s3:PutObject",
       "Resource": "${aws_s3_bucket.this.arn}/*"
     },
     {
       "Effect": "Allow",
       "Principal": {
         "Service": "delivery.logs.amazonaws.com"
       },
       "Action": "s3:PutObject",
       "Resource": "${aws_s3_bucket.this.arn}/*",
       "Condition": {
         "StringEquals": {
           "s3:x-amz-acl": "bucket-owner-full-control"
         }
       }
     },
     {
       "Effect": "Allow",
       "Principal": {
         "Service": "delivery.logs.amazonaws.com"
       },
       "Action": "s3:GetBucketAcl",
       "Resource": aws_s3_bucket.this.arn
     },
      {
        "Sid" : "AllowSSLRequestsOnly",
        "Action" : "s3:*",
        "Effect" : "Deny",
        "Resource" : [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
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

resource "aws_s3_bucket_public_access_block" "elb_logs" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
