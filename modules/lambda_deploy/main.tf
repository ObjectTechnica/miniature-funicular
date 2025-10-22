data "aws_caller_identity" "current" {}

# Create Lambda function
resource "aws_lambda_function" "snapshot_checker" {
  filename         = data.archive_file.lambda_zip.output_path
  description      = "${var.function_description}" 
  function_name    = var.function_name
  role             = aws_iam_role.iam_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.12"

  environment {
    variables = var.lambda_env_vars
  }

  timeout = var.lambda_timeout
  memory_size = var.lambda_mem_limit

  tracing_config {
    mode = "Active"
  }

  logging_config {
    log_format = "Text"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_code"
  output_path = "${path.module}/lambda_function.zip"
}


resource "aws_iam_role" "iam_role" {
  name = "${var.function_name}_lambda_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}


# Determine which role ARN and name to use
locals {
  effective_lambda_role_arn  = var.lambda_role_arn != "" ? var.lambda_role_arn : aws_iam_role.iam_role[0].arn
  effective_lambda_role_name = var.lambda_role_arn != "" ? element(split("/", var.lambda_role_arn), 1) : aws_iam_role.iam_role[0].name
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  count      = var.lambda_role_arn == "" ? 1 : 0
  role       = local.effective_lambda_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "aws_xray_write_only_access" {
  count      = var.lambda_role_arn == "" ? 1 : 0
  role       = local.effective_lambda_role_name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}