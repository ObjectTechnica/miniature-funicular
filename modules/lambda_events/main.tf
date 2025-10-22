resource "aws_cloudwatch_event_rule" "snapshot_schedule" {
  name        = "${var.function_name}-StateRunning"
  description = "Triggers when an scheduled rotation."
  schedule_expression = "cron(0 6 1 * ? *)" # 1st of month at 6:00 UTC }
}

resource "aws_iam_role" "eventbridge_sfn_role" {
  name = "${var.function_name}-EventBridgeRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "eventbridge_sfn_policy" {
  name   = "${var.function_name}-BridgeToStepPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "states:StartExecution",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_sfn_policy_attach" {
  role       = aws_iam_role.eventbridge_sfn_role.id
  policy_arn = aws_iam_policy.eventbridge_sfn_policy.arn
}

resource "aws_cloudwatch_event_target" "invoke_step_function" {
  rule      = aws_cloudwatch_event_rule.snapshot_schedule.name
  target_id = "${var.function_name}-Target"
  arn       = "${var.step_function_arn}"
  role_arn  = aws_iam_role.eventbridge_sfn_role.arn

input = jsonencode({
    roles = var.snapshot_checker_roles
  })
}

