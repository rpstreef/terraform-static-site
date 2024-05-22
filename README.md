# Terraform Static Site

## Installation

Clone this repo and adjust the following for your specific product:

1) Setup your specific static site environment in the `./environments/production/terraform.tfvars` file first;

```bash
hosted_zone_id = "Z000..."
bucket_name    = "yourwebsite.com"
aws_profile    = "yourwebsite-prod"
```

- `hosted_zone_id` is the identifier of your particular domain name, you can find it through the Route53 AWS CLI or in the AWS console.
- `bucket_name` domain name for your static site. This name **must** match with the domain name in the `hosted_zone_id`.
- `aws_profile` in your `~/.aws/config` file create a name that points to the AWS account number with the domain `hosted_zone_id` and S3 `bucket_name`

2) Modify `environments/production/main.tf`:

Adjust your specific details in the locals definition first;

```h
locals {
  bucket_name = "tfstate-yourwebsite"
  tags = {
    Terraform   = "true"
    Environment = "production"
    Product     = "YourWebsite"
  }
}
```

and enable local state:

```h
terraform {
  backend "local" {
  }
  /* backend "s3" {
    bucket  = "tfstate-yourwebsite"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    profile = "yourwebsite-prod"

    encrypt = true
    acl     = "private"
  } */
}
```

3) Adjust `provider.tf`:

input the correct `profile` name, the same as `aws_profile`;

```h
provider "aws" {
  region  = "us-east-1"
  profile = "yourwebsite-prod"
}
```

4) Run Terraform deployment;

```bash
cd environments/production/
terraform init
terraform apply
```

4) Change the backend to S3:

```h
terraform {
  backend "s3" {
    bucket  = "tfstate-yourwebsite"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    profile = "yourwebsite-prod"

    encrypt = true
    acl     = "private"
  }
}
```

5) Migrate the backend state;

```bash
terraform init -migrate-state
```