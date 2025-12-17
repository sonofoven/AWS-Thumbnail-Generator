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
gh secret delete ECR_REPOSITORY
gh secret delete AWS_REGION
gh secret delete LAMBDA_FUNCTION_NAME
