output "step_function_arn" {
   description = "The AWS ARN of the deployed lambda function"
   value       = aws_sfn_state_machine.snapshot_scan.arn
}

output "step_function_role_arn" {
   description = "The AWS ARN of the deployed lambda function role"
   value       = aws_iam_role.step_functions_role.arn
}