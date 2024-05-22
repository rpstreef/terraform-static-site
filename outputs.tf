output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket for the static site"
  value       = module.s3_static_site.s3_bucket_arn
}

output "certificate_arn" {
  description = "The ARN of the certificate"
  value       = var.is_top_level_domain ? module.acm_certificate[0].certificate_arn : var.provided_certificate_arn
}
