locals {
  s3_origin_id         = var.bucket_name
  lambda_qualified_arn = "${aws_lambda_function.redirect.arn}:${aws_lambda_function.redirect.version}"
}

# Create an S3 bucket for hosting the static website
resource "aws_s3_bucket" "my_bucket" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_cors_configuration" "_" {
  count   = var.bucket_cors != null ? 1 : 0
  bucket  = aws_s3_bucket.my_bucket.id

  dynamic "cors_rule" {
    for_each = var.bucket_cors != null ? var.bucket_cors : {}
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.my_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal : {
          Service : "cloudfront.amazonaws.com"
        },
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.my_bucket.arn}",
          "${aws_s3_bucket.my_bucket.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution._.arn
          }
        }
      }
    ]
  })
}

#
# Lambda At Edge
#
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.bucket_name}-lambda_edge_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "edgelambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "lambda_edge_policy" {
  name        = "${var.bucket_name}-lambda_edge_policy"
  description = "Policy for Lambda@Edge function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource : "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action : [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource : [
          "arn:aws:s3:::${var.bucket_name}/*",
          "arn:aws:s3:::${var.bucket_name}"
        ]
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_edge_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_edge_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}


resource "aws_lambda_function" "redirect" {
  function_name    = "${var.product_name}-redirect-to-index"
  handler          = "index.handler"
  role             = aws_iam_role.lambda_execution_role.arn
  runtime          = "nodejs14.x"
  filename         = "${path.module}/redirect.zip"
  source_code_hash = filebase64sha256("${path.module}/redirect.zip")
  publish          = true

  tags = var.tags
}

#
# Create a CloudFront distribution
#

resource "aws_cloudfront_function" "redirect" {
  name    = "${var.product_name}-redirect-to-index"
  comment = "Lambda function to redirect requests to index.html"
  runtime = "cloudfront-js-1.0"
  publish = true
  code    = filebase64("${path.module}/redirect.zip")
}

resource "aws_cloudfront_origin_access_control" "_" {
  name                              = var.bucket_name
  description                       = var.product_name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "_" {
  # General settings
  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.bucket_name
  price_class         = "PriceClass_100"
  aliases             = var.domain_names
  http_version        = "http2and3"
  default_root_object = "index.html"

  # Default cache behavior
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    compress = true

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 1
    default_ttl            = 86400
    max_ttl                = 31536000

    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = "${aws_lambda_function.redirect.arn}:${aws_lambda_function.redirect.version}"
      include_body = false
    }
  }

  # SSL settings
  viewer_certificate {
    acm_certificate_arn = var.certificate_arn
    ssl_support_method  = "sni-only"
  }

  # Origin settings
  origin {
    domain_name              = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control._.id
  }

  dynamic "origin" {
    for_each = var.additional_origins
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.value.origin_id

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.additional_origins
    content {
      path_pattern     = ordered_cache_behavior.value.path_pattern
      target_origin_id = ordered_cache_behavior.value.origin_id

      allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods  = ["GET", "HEAD"]

      forwarded_values {
        query_string = true
        headers      = ["Host"]

        cookies {
          forward = "none"
        }
      }

      min_ttl                = 0
      default_ttl            = 3600
      max_ttl                = 86400
      viewer_protocol_policy = "redirect-to-https"
      compress               = true
    }
  }


  # Restrictions (optional)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = var.tags
}

#
# Route 53
#
resource "aws_route53_record" "record" {
  for_each = toset(var.domain_names)

  zone_id = var.hosted_zone_id
  name    = each.key
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution._.domain_name
    zone_id                = aws_cloudfront_distribution._.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "record_ipv6" {
  for_each = toset(var.domain_names)

  zone_id = var.hosted_zone_id
  name    = each.key
  type    = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution._.domain_name
    zone_id                = aws_cloudfront_distribution._.hosted_zone_id
    evaluate_target_health = false
  }
}

# Resources for "A" and "AAAA" records using aliases
resource "aws_route53_record" "alias_record" {
  for_each = { for index, domain in var.additional_sub_domains : index => domain if (domain.type == "A" || domain.type == "AAAA") && domain.zone_id != null }

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type

  dynamic "alias" {
    for_each = each.value.type == "A" || each.value.type == "AAAA" ? [1] : []
    content {
      name                   = each.value.target
      zone_id                = each.value.zone_id
      evaluate_target_health = false
    }
  }
}

# Resources for other record types using records
resource "aws_route53_record" "non_alias_record" {
  for_each = { for index, domain in var.additional_sub_domains : index => domain if domain.type != "A" && domain.type != "AAAA" }

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.target]
}
