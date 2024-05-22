variable "bucket_name" {
  description = "The name of the S3 bucket for the static site"
}

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

variable "domain_names" {
  description = "List of domain names for the applications"
  type        = list(string)
  default     = ["app1.example.com", "app2.example.com"]
}

variable "hosted_zone_id" {
}

variable "tags" {
}

variable "product_name" {

}

variable "certificate_arn" {

}

variable "additional_origins" {
  description = "A list of maps for additional origins, in the format [{domain_name = \"example.com\", origin_id = \"example_origin_id\", path_pattern = \"/example_path/*\"}, ...]"
  type = list(object({
    domain_name  = string
    origin_id    = string
    path_pattern = string
  }))
  default = []
}

variable "additional_sub_domains" {
  description = "A map of additional subdomains and their targets"
  type = list(object({
    name    = string # the subdomain name
    zone_id = optional(string)
    type    = string # e.g., "A", "AAAA", "CNAME"
    target  = string # the target endpoint, such as NLB or EC2 DNS
  }))
  default = []
}
