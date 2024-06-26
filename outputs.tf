output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket for the static site"
  value       = module.s3_static_site.s3_bucket_arn
}

output "certificate_arn" {
  description = "The ARN of the certificate"
  value       = var.is_top_level_domain ? module.acm_certificate[0].certificate_arn : var.provided_certificate_arn
}

output "cloudfront_distribution_id" {
  value = module.s3_static_site.cloudfront_distribution_id
}

output "aws_access_key_id" {
  value = module.iam.aws_access_key_id
}

output "aws_secret_access_key" {
  value = module.iam.aws_secret_access_key
}