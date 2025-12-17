variable "aws_region" {
  description = "AWS region where computation & storage occurs"
  type        = string
}

variable "input_bucket_name" {
  description = "Name of the input bucket for the pipeline"
  type        = string
}

variable "output_bucket_name" {
  description = "Name of the output bucket for the pipeline"
  type        = string
}

variable "lambda_func_name" {
  description = "Name of the lambda function"
  type        = string
}

variable "lambda_role_name" {
  description = "Name of the role that lambda needs"
  type        = string
}

variable "ecr_repo_name" {
  description = "Name of ecr repository"
  type        = string
}

variable "ecr_registry_id" {
  description = "Registry id of the ecr repository"
  type = string
}
