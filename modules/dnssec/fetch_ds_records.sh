#!/bin/bash
hosted_zone_id=$1
aws_profile=$2

response=$(aws route53 get-dnssec --hosted-zone-id "$hosted_zone_id" --profile "$aws_profile")
if [ $? -ne 0 ]; then
  echo "Error fetching DS records from AWS Route53:" >&2
  echo "$response" >&2
  exit 1
fi

ds_records=$(echo "$response" | jq -r '.KeySigningKeys[] | select(.Status == "ACTIVE") | .DNSKEYRecord' | paste -sd "," -)
if [ -z "$ds_records" ]; then
  echo "Error: DS records not found" >&2
  exit 1
fi

echo "{\"ds_records\": \"$ds_records\"}"