output "aws_access_key_id" {
  value = aws_iam_access_key.spacelift_user_key.id
}

output "aws_secret_access_key" {
  value = aws_iam_access_key.spacelift_user_key.secret
}