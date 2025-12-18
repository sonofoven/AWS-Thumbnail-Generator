# AWS Lambda Thumbnail Generator

AWS Lambda Thumbnail Generator is a serverless thumbnail generator built on AWS Lambda and Amazon S3, with all infrastructure provisioned via Terraform. The project is designed so that a single bootstrap script can take an empty AWS account and turn it into a fully functional thumbnail service backed by a containerized Lambda function.

When a new image is uploaded to the configured S3 bucket, the Lambda function is triggered, downloads the image, generates a thumbnail using Pillow, and writes the result to a destination bucket.

Development of the lambda runtime is made easy by the Github Actions integration. 


## Features

- Serverless thumbnail generation via AWS Lambda (container image)
- S3 event–driven workflow for fully automated processing
- Infrastructure-as-code with Terraform (IAM, S3, ECR, Lambda)
- One-command bootstrap to provision everything and push the initial image
- GitHub Actions integration using repo secrets for ongoing deployments



## Project Structure

```text
.
├── pySrc
│   ├── Dockerfile          # Lambda container image definition
│   ├── lambda_function.py  # Lambda handler that generates thumbnails
│   └── requirements.txt    # Python deps: boto3, Pillow
├── scripts
│   ├── bootstrap.sh        # One-shot provisioning + initial deploy
│   ├── destroyAll.sh       # Tear down all infra and related secrets
│   └── pushImage.sh        # Build and push Lambda image to ECR
└── terraform
    ├── dependencies        # ECR, IAM, S3, and shared infra
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── lambda              # Lambda function and related config
    │   ├── main.tf
    │   └── variables.tf
    └── shared.tfvars       # Shared variables for both stacks
```

The Lambda runtime depends on `boto3` (for S3 access) and `Pillow` (for image processing).



## Prerequisites

You will need:

- An AWS account with permissions to manage IAM, S3, ECR, and Lambda
- AWS CLI configured locally
- Terraform installed
- Docker with `buildx` support
- GitHub CLI (`gh`) authenticated against the repository (for managing secrets)
- A GitHub repository hosting this project (for CI/CD integration)



## Bootstrap: First-Time Setup

From the project root, run:

```bash
cd scripts
./bootstrap.sh
```

This script will:

1. Initialize and apply `terraform/dependencies` to provision core resources (ECR repo, region, and other dependencies), then capture outputs such as `ecr_repository_url`, `aws_region`, and `lambda_func_name`.
2. Build and push the Lambda container image from `pySrc` to the new ECR repository using `pushImage.sh`.
3. Initialize and apply `terraform/lambda` to create the Lambda function wired up to the input S3 bucket.
4. Store the key bootstrap outputs into GitHub repo secrets: `ECR_REPOSITORY`, `AWS_REGION`, and `LAMBDA_FUNCTION_NAME`, enabling a GitHub Actions workflow to build and deploy updates on pushes (typically to `main`).

After this completes, the account is ready to act as a thumbnail generator host.



## Teardown

To remove all provisioned resources and clean up GitHub secrets:

```bash
cd scripts
./destroyAll.sh
```

This script:

- Destroys the Terraform Lambda stack
- Destroys the Terraform dependencies stack
- Deletes the GitHub repo secrets `ECR_REPOSITORY`, `AWS_REGION`, and `LAMBDA_FUNCTION_NAME`



## Automatic Deployment via GitHub Actions

This project ships with an automated deployment workflow defined in `.github/workflows/deploy.yml`. On every push to the `main` branch with changes to the workflow or any file under pySrc, GitHub Actions:

1. Checks out the repository.
2. Configures AWS credentials using the `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_REGION` secrets.
3. Uses Docker Buildx to build and push the Lambda container image to the ECR repository specified by the `ECR_REPOSITORY` secret (via `scripts/pushImage.sh`).
4. Updates the running Lambda function to the newly built `:latest` image in ECR using the `LAMBDA_FUNCTION_NAME` secret.

This enables a simple “push-to-main” workflow where committing code to `main` automatically builds, pushes, and deploys the updated Lambda container image. 



## Runtime Behavior

At a high level, the Lambda handler:

1. Reads the S3 event to determine the source bucket and key.
2. Downloads the original object using `boto3`.
3. Uses Pillow’s `Image.thumbnail` to generate a `256x256` thumbnail.
4. Writes the thumbnail as a JPEG to the configured destination bucket.

Once deployed and wired to the appropriate S3 bucket notifications, simply uploading an image to the source bucket will result in an automatically generated thumbnail in the output bucket.
