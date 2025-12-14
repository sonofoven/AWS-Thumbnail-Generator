variable "input_bucket_name" {
  description = "Name of the input bucket for the pipeline"
  type = string
  default = "s3-thumbnailer-gen-input"
}

variable "output_bucket_name" {
  description = "Name of the output bucket for the pipeline"
  type = string
  default = "s3-thumbnailer-gen-output"
}

variable "lambda_func_name" {
  description = "Name of the lambda function"
  type = string
  default = "Thumbnail-Generator"
}
