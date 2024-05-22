#!/bin/bash

# Set AWS profile
AWS_PROFILE_NAME="yourwebsite-prod"

# List of resources to import in the format <terraform resource type>.<resource name>=<aws resource id>
declare -A resources=(
    ["module.app_s3_static_site.aws_s3_bucket.my_bucket"]="app.yourwebsite.io"
)

# Loop over each resource to import
for resource in "${!resources[@]}"; do
    echo "Importing $resource..."
    AWS_PROFILE=$AWS_PROFILE_NAME terraform import $resource ${resources[$resource]}
    if [ $? -eq 0 ]; then
        echo "Successfully imported $resource"
    else
        echo "Failed to import $resource"
    fi
done
