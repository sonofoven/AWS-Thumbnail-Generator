#!/bin/sh

# Shift to proj root dir
cd ..

# Provision dependencies
echo "<< PROVISIONING DEPENDENCIES >>"

cd terraform/dependencies
terraform init
terraform apply -auto-approve -var-file="../shared.tfvars"

ECR_REPOSITORY_URL=$(terraform output -raw ecr_repository_url)
AWS_REGION=$(terraform output -raw aws_region)
LAMBDA_FUNCTION_NAME=$(terraform output -raw lambda_func_name)


# Push initial image to ecr
cd ../../scripts

echo "<< BUILDING AND PUSHING IMAGE >>"
./pushImage.sh $ECR_REPOSITORY_URL $AWS_REGION


# Provision lambda function
echo "<< CREATING LAMBDA FUNCTION >>"
cd ../terraform/lambda
terraform init
terraform apply -auto-approve -var-file="../shared.tfvars"

cd ../..
echo "ECR_REPOSITORY_URL=$ECR_REPOSITORY_URL"
echo "AWS_REGION=$AWS_REGION"
echo "LAMBDA_FUNCTION_NAME=$LAMBDA_FUNCTION_NAME"

# Store bootstrap info into gh secrets
echo "<< STORING BOOTSTRAP VARS >>"
gh variable set ECR_REPOSITORY --body "$ECR_REPOSITORY_URL"
gh variable set AWS_REGION --body "$AWS_REGION"
gh variable set LAMBDA_FUNCTION_NAME --body "$LAMBDA_FUNCTION_NAME"
