variable "region" {
  default     = "us-east-1"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "snapshot-lifecycle"
}

variable "lambda_env_vars" {
  description = "Lambda specific ENV vars"
  type = map(string)
  default = {
    "DAYS_THRESHOLD"  = "30"
  }
}

variable "lambda_timeout" {
  description = "Defined Lambda time limit"
  default     = "300" 
}

variable "lambda_mem_limit" {
  description = "Defined memory Limit for Lambda"
  default     = "512" 
}

variable "snapshot_checker_roles" {
type = list(string)
description = "List of cross-account role ARNs"
}
