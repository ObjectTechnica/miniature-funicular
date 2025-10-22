resource "aws_iam_role" "step_functions_role" {
  name = "${var.function_name}-StepFunctionsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "states.amazonaws.com"
      },
      Effect = "Allow",
      Sid = ""
    }]
  })
}

resource "aws_iam_policy" "step_functions_lambda_policy" {
  name   = "${var.function_name}-ExecutionPolicy"
  path   = "/"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "lambda:InvokeFunction",
        "lambda:InvokeAsync"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_policy" "step_functions_logs_policy" {
  name   = "${var.function_name}-LogsPolicy"
  path   = "/"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups",
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
          "sts:AssumeRole"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_functions_logs_attach" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.step_functions_logs_policy.arn
}

resource "aws_iam_role_policy_attachment" "step_functions_lambda_attach" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.step_functions_lambda_policy.arn
}

resource "aws_sfn_state_machine" "snapshot_scan" {
  name     = "${var.function_name}-state-machine"
  role_arn = aws_iam_role.step_functions_role.arn

  logging_configuration {
    level                  = "ALL"
    include_execution_data = true
    log_destination        = "${aws_cloudwatch_log_group.step_function_logging.arn}:*"
  }

  definition = templatefile("${path.module}/step_function_snapshot_scan.asl.json",
{
    lambda_arn = var.lambda_function_arn
  })

  type = "STANDARD"
}


resource "aws_cloudwatch_log_group" "step_function_logging" {
  name = "/aws/stepfunctions/${var.function_name}-sfn"
  retention_in_days = 14
}