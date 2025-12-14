provider "aws" {
  region = "us-west-1"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {} 

locals {
  account_id = data.aws_caller_identity.current.account_id
  region = data.aws_region.current.name

  policy_arns = {
    s3Access = aws_iam_policy.AWS_S3_Put_Get.arn
    logAccess = aws_iam_policy.AWS_Logging_Access.arn
  }
}

### Provision underlying resources ###

## Create policies and attach to role

resource "aws_iam_policy" "AWS_S3_Put_Get" { #
  name        = "AWS_S3_Put_Get"
  path        = "/"
  description = "Enables Put & Get for the thumbnailer I/O bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
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

resource "aws_iam_policy" "AWS_Logging_Access" { #
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
  for_each = local.policy_arns
  role = aws_iam_role.Lambda_S3_Access_Role
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

resource "aws_iam_role" "Lambda_S3_Access_Role" { # Create base role for policies to attach to
  name = "LambdaS3AccessRole"
  description = "Gives lambda access to execution, logging, and s3"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

## Create Buckets

resource "aws_s3_bucket" "S3_Input_Bucket" {
  bucket = var.input_bucket_name

  tags = {
    Name = "Thumbnail Generator"
  }
}

resource "aws_s3_bucket" "S3_Output_Bucket" {
  bucket = var.output_bucket_name

  tags = {
    Name = "Thumbnail Generator"
  }
}

## Create ECR

resource "aws_ecr_repository" "Lambda_Thumbnail_Generator" {
  name                 = "lambda-thumbnail-generator"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

### Provision lambda once container uploaded to ECR ###


