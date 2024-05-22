module "acm_certificate" {
  count = var.is_top_level_domain ? 1 : 0

  source = "./modules/acm"

  domain_name    = var.bucket_name
  hosted_zone_id = var.hosted_zone_id

  tags = var.tags
}
module "dnssec" {
  count = var.is_top_level_domain ? 1 : 0

  source = "./modules/dnssec"

  domain_name    = var.bucket_name
  aws_profile    = var.aws_profile
  hosted_zone_id = var.hosted_zone_id

  tags = var.tags
}

module "s3_static_site" {
  source = "./modules/s3-static-site"

  bucket_name     = var.bucket_name
  bucket_cors     = var.bucket_cors
  domain_names    = var.domain_names
  hosted_zone_id  = var.hosted_zone_id
  product_name    = var.product_name
  certificate_arn = var.is_top_level_domain ? module.acm_certificate[0].certificate_arn : var.provided_certificate_arn

  additional_origins     = var.additional_origins
  additional_sub_domains = var.additional_sub_domains

  tags = var.tags
}
