
resource "aws_iam_user" "spacelift_user" {
  name = "spacelift-user"

  tags = var.tags
}

resource "aws_iam_policy" "s3_and_cloudfront_policy" {
  name        = "S3AndCloudFrontPolicy"
  path        = "/"
  description = "Policy for deploying to S3 and invalidating CloudFront"
    
  tags = var.tags
  
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3Deployment",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::${var.bucket_name}/*",
        "arn:aws:s3:::${var.bucket_name}"
      ]
    },
    {
      "Sid": "CloudFrontInvalidation",
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateInvalidation"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "spacelift_user_policy_attachment" {
  user       = aws_iam_user.spacelift_user.name
  policy_arn = aws_iam_policy.s3_and_cloudfront_policy.arn
}

resource "aws_iam_access_key" "spacelift_user_key" {
  user = aws_iam_user.spacelift_user.name
}