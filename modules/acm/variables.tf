variable "domain_name" {
  description = "The domain name for the ACM Certificate"
  type        = string
}

variable "hosted_zone_id" {
  description = "The Route53 Hosted Zone ID"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

