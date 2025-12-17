output "ecr_repository_url" {
  value = aws_ecr_repository.lambda_repo.repository_url
}

output "lambda_func_name" {
  value = var.lambda_func_name
}

output "ecr_registry_url" {
  value = "${aws_ecr_repository.lambda_repo.registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

output "aws_region" {
  value = var.aws_region
}

