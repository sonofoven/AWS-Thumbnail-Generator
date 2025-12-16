terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"
}

provider "aws" {
  region = var.aws_region
}

data "aws_iam_role" "lambda_s3_access_role" {
  name = var.lambda_role_name
}

data "aws_ecr_repository" "ecr_repo" {
  name = var.ecr_repo_name
}

data "aws_s3_bucket" "s3_input_bucket" {
  bucket = var.input_bucket_name
}

### Provision lambda function + triggers after container has been uploaded

locals {
  ecr_repo_url = data.aws_ecr_repository.ecr_repo.repository_url
  lambda_role_arn = data.aws_iam_role.lambda_s3_access_role.arn
  s3_input_arn = data.aws_s3_bucket.s3_input_bucket.arn
}

## Create lambda function

resource "aws_lambda_function" "thumbnail_generator" {
  function_name = var.lambda_func_name
  role          = local.lambda_role_arn
  package_type  = "Image"
  image_uri     = "${local.ecr_repo_url}:latest"
  runtime = "python3.12"

  architectures = ["x86_64"] 
}

## Create triggers w/ permissions

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_func_name
  principal     = "s3.amazonaws.com"
  source_arn    = local.s3_input_arn
}

resource "aws_s3_bucket_notification" "input_object_created" {
  bucket = var.input_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.thumbnail_generator.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [
    aws_lambda_permission.allow_s3_invoke,
  ]
}


