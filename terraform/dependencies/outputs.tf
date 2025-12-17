output "ecr_repository_url" {
  value = aws_ecr_repository.lambda_repo.repository_url
}

output "lambda_func_name" {
  value = var.lambda_func_name
}

output "aws_region" {
  value = var.aws_region
}

