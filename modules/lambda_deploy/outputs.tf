output "lambda_function_name" {
  description = "The deployed Lambda function name"
  value       = aws_lambda_function.snapshot_checker.function_name
}

output "lambda_function_arn" {
  description = "The deployed Lambda function ARN"
  value       = aws_lambda_function.snapshot_checker.arn
}
