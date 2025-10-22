# 📸 AWS Snapshot Checker – Cross-Account EBS Audit with Automation

This solution provides a secure and scalable mechanism to audit **EBS snapshots across multiple AWS accounts** using:

- ✅ A Lambda function that assumes roles into other accounts
- 🔁 A Step Function that orchestrates parallel execution per account
- 📅 An EventBridge rule that triggers the workflow monthly

### All components are deployed using **modular Terraform**, making this easily reusable across environments.


## 🚀 Features

- 🔍 Identifies snapshots older than a configurable threshold
- 🔁 Scans **multiple AWS accounts concurrently** via `Map` state in Step Functions
- 🔐 Uses cross-account IAM roles for secure access
- 📜 Logs detailed snapshot metadata tagged by account
- 📆 Runs automatically on a **monthly EventBridge schedule**
- 🧱 Modular Terraform structure (`lambda`, `step_function`, `eventbridge` modules)

## 📁 Module Structure

modules/
├── lambda/
│ ├── main.tf
│ ├── variables.tf
│ ├── outputs.tf
│ ├── lambda_function.py
├── step_function/
│ ├── main.tf
│ ├── step_function_snapshot_scan.asl.json
│ ├── variables.tf
│ ├── outputs.tf
├── eventbridge/
│ ├── main.tf
│ ├── variables.tf
│ ├── outputs.tf


## 🧩 Resource Overview

| Resource                                 | Purpose
                                              |
|------------------------------------------|-------------------------------------------------------------------------|
| `aws_lambda_function`                    | Scans snapshots using an assumed role                                   |
| `aws_iam_role` (lambda + stepfn)         | Execution roles with logging and `sts:AssumeRole` permissions           |
| `aws_iam_policy_document`                | IAM policy and trust setup using data blocks                            |
| `aws_sfn_state_machine`                  | Orchestrates snapshot scanning per account with concurrency             |
| `aws_cloudwatch_log_group`               | Logs for Step Function executions                                       |
| `aws_cloudwatch_event_rule`              | Triggers Step Function monthly                                          |
| `aws_cloudwatch_event_target`            | Connects EventBridge rule to Step Function                              |
| `aws_lambda_permission`                  | Allows EventBridge to invoke Step Function                              |

---

## 📦 Lambda Function

- Assumes a role in each target account using STS
- Retrieves and filters snapshots older than `DAYS_THRESHOLD`
- Logs snapshot IDs and timestamps, tagged with the source account ID

**Environment Variables:**

```hcl
DAYS_THRESHOLD = 30
Input Payload (from Step Function):
{
  "role": "arn:aws:iam::111111111111:role/SnapshotScanRole"
}
```

### 🔁 Step Function
Uses a Map state to iterate over roles list

Invokes Lambda once per role in parallel

ASL Template: step_function_snapshot_scan.asl.json

### Terraform Integration:

```hcl
definition = templatefile("${path.module}/step_function_snapshot_scan.asl.json",
{
  lambda_arn = aws_lambda_function.snapshot_checker.arn
})
```

### Terraform TFVRS Input:

```hcl
{
  "roles": [
    "arn:aws:iam::111111111111:role/SnapshotScanRole",
    "arn:aws:iam::222222222222:role/SnapshotScanRole"
  ]
}
```

### 🕒 EventBridge Schedule
Runs the Step Function on a monthly basis.  Can be customized using
cron() or rate() expressions

```hcl
schedule_expression = "cron(0 6 1 * ? *)"  # 6:00 AM UTC on the 1st of every month 
```

### Sample CloudWatch Logs

```hcl
INFO:root:Assuming role: arn:aws:iam::111111111111:role/SnapshotScanRole
INFO:root:Found 3 old snapshots in account 111111111111:
INFO:root:Snapshot ID: snap-0ab123456789cdef0, Start Time: 2023-02-01 12:00:00+00:00 from account 111111111111 
```
