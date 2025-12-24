#!/bin/sh

# Shift to proj root dir
cd ..

# Remove lambda function
cd terraform/lambda
terraform destroy -auto-approve -var-file="../shared.tfvars"

# Remove dependencies
cd ../dependencies
terraform destroy -auto-approve -var-file="../shared.tfvars"

# Remove gh secrets
cd ../..
gh variable delete ECR_REPOSITORY
gh variable delete AWS_REGION
gh variable delete LAMBDA_FUNCTION_NAME
