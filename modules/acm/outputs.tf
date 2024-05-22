output "certificate_arn" {
  description = "The ARN of the ACM certificate"
  value       = aws_acm_certificate._.arn
}

output "validation_record_fqdns" {
  description = "List of FQDNs built from the record_name and record_type of the validation_records"
  value       = [for record in aws_route53_record.acm_validation : record.fqdn]
}
