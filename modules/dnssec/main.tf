resource "aws_route53_key_signing_key" "dnssecksk" {
  name = var.domain_name
  hosted_zone_id = var.hosted_zone_id
  key_management_service_arn = aws_kms_key.dnssecksk.arn
}

resource "aws_route53_hosted_zone_dnssec" "example" {
  depends_on = [
    aws_route53_key_signing_key.dnssecksk
  ]
  hosted_zone_id = aws_route53_key_signing_key.dnssecksk.hosted_zone_id
}

resource "aws_kms_key" "dnssecksk" {
  customer_master_key_spec = "ECC_NIST_P256"
  deletion_window_in_days  = 7
  key_usage                = "SIGN_VERIFY"
  policy = jsonencode({
    Statement = [
      {
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign",
        ],
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Sid      = "Allow Route 53 DNSSEC Service",
        Resource = "*"
      },
      {
        Action = "kms:CreateGrant",
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Sid      = "Allow Route 53 DNSSEC Service to CreateGrant",
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      },
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Resource = "*"
        Sid      = "IAM User Permissions"
      },
    ]
    Version = "2012-10-17"
  })

  tags = var.tags
}