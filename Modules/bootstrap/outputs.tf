output "bucket_arn" {
  value = aws_s3_bucket.state_bucket.arn
}

output "alb_logging_s3" {
  value = aws_s3_bucket.this.bucket
}
/* 
output "s3_logging_bucket" {
  value = module.s3_logging.id
} */