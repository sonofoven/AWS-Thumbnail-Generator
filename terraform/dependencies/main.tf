### Define terraform setup & vars

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

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  policy_arns = {
    s3Access  = aws_iam_policy.s3_put_get.arn
    logAccess = aws_iam_policy.logging_access.arn
  }
}

### Provision underlying resources ###

## Create policies and attach to role

resource "aws_iam_policy" "s3_put_get" {
  name        = "AWS_S3_Put_Get"
  path        = "/"
  description = "Enables Put & Get for the thumbnailer I/O bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject",
        "s3:PutObject"]
        Resource = ["arn:aws:s3:::${var.input_bucket_name}",
          "arn:aws:s3:::${var.input_bucket_name}/*",
          "arn:aws:s3:::${var.output_bucket_name}",
          "arn:aws:s3:::${var.output_bucket_name}/*"
        ]
      },
    ]
  })
}

resource "aws_iam_policy" "logging_access" {
  name        = "AWS_Logging_Access"
  description = "Enables creation of logging groups, streams, and events"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${var.lambda_func_name}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach" { # Attach policies to role
  for_each   = local.policy_arns
  role       = aws_iam_role.lambda_s3_access_role.name
  policy_arn = each.value
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_s3_access_role" { # Create base role for policies to attach to
  name               = "LambdaS3AccessRole"
  description        = "Gives lambda access to execution, logging, and s3"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

## Create Buckets

resource "aws_s3_bucket" "input_bucket" {
  bucket = var.input_bucket_name

  tags = {
    Name = "Thumbnail Generator"
  }
}

resource "aws_s3_bucket" "output_bucket" {
  bucket = var.output_bucket_name

  tags = {
    Name = "Thumbnail Generator"
  }
}

## Create ECR

resource "aws_ecr_repository" "lambda_repo" {
  name                 = "lambda-thumbnail-generator"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

### Provision lambda once container uploaded to ECR ###
