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

