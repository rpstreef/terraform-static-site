output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket for the static site"
  value       = aws_s3_bucket.my_bucket.arn
}
