# Terraform Static Site

## Resources create

- ACM Certificate for `*.yourdomain.com`
  - Route53 ACM Validation for SSL auto-renewal
- IAM User that is allowed to;
  - Deploy to S3
  - Invalidate all CloudFront caches.
- AWS Route53
  - DNSSec (step 1 of 2) Route53 signing record
  - AMS Key for the signature with policy
  - A, AAAA Records to CloudFront distribution for; `yourwebsite.com` and `www.yourwebsite.com`
- S3 Buckets;
  - Terraform state
  - For `yourdomain.com` with access policy for CloudFront
    - (optional) CORS configuration
    - CORS configuration via variable; `bucket_cors`
- CloudFront Distribution 
  - Enabled; `http2and3`, `PriceClass_100`, default root `index.html`
    - with optional Custom Error Pages via variable; `custom_error_responses`
  - CloudFront function > AWS Lambda@Edge for URL rewrites

## How to import

Within your Terraform project, add the following module:

```h
module "s3_static_site" {
  source = "git::https://github.com/rpstreef/terraform-static-site"

  aws_profile         = var.aws_profile
  hosted_zone_id      = var.hosted_zone_id
  is_top_level_domain = true

  product_name = var.product_name
  bucket_name  = var.bucket_name
  bucket_cors  = var.bucket_cors
  domain_names = var.domain_names

  custom_error_responses = var.custom_error_responses

  tags = var.tags
}
```

Take note of the complex variables; `bucket_cors` and `custom_error_responses`:

```h
variable "bucket_cors" {
  type = map(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default = null
}

variable custom_error_responses {
  description = "A list of maps for custom error responses, e.g. 404 redirects to /404.html with response 200"
  type = list(object({
      error_code = number
      error_caching_min_ttl = number
      response_code = number
      response_page_path = string
  }))
  default = []
}
```
in your `.tfvars` file you can use them like this:

```h
# S3 Bucket CORS rules:
bucket_cors = {
  rule1 = {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["https://f.convertkit.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# CloudFront Custom Error Responses
custom_error_responses = [{
  error_code = 404
  error_caching_min_ttl = 10
  response_code = 200
  response_page_path = "/404.html"
}]
```