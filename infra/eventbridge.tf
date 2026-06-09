# ── IAM role for scheduled Lambdas ───────────────────────────────────────────
resource "aws_iam_role" "scheduled_lambda" {
  name = "wp-platform-scheduled-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "scheduled_lambda_policy" {
  name = "wp-platform-scheduled-lambda-policy"
  role = aws_iam_role.scheduled_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb:Query", "dynamodb:Scan", "dynamodb:PutItem", "dynamodb:UpdateItem"]
        Resource = [
          aws_dynamodb_table.sites.arn,
          "${aws_dynamodb_table.sites.arn}/index/*",
          aws_dynamodb_table.backups.arn,
        ]
      },
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.alerts.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ── Health-check Lambda (every 5 minutes) ─────────────────────────────────────
resource "aws_lambda_function" "health_check" {
  function_name    = "wp-platform-health-check"
  filename         = "${path.module}/scheduled_tasks.zip"
  source_code_hash = filebase64sha256("${path.module}/scheduled_tasks.zip")
  handler          = "scheduled_tasks.health_check"
  runtime          = "python3.12"
  role             = aws_iam_role.scheduled_lambda.arn
  timeout          = 60

  environment {
    variables = {
      SITES_TABLE     = aws_dynamodb_table.sites.name
      ALERT_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }

  tags = { Name = "wp-platform-health-check" }
}

resource "aws_cloudwatch_log_group" "health_check" {
  name              = "/aws/lambda/${aws_lambda_function.health_check.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_event_rule" "health_check" {
  name                = "wp-platform-health-check"
  schedule_expression = "rate(5 minutes)"
  description         = "Run site health checks every 5 minutes"
}

resource "aws_cloudwatch_event_target" "health_check" {
  rule      = aws_cloudwatch_event_rule.health_check.name
  target_id = "health-check-lambda"
  arn       = aws_lambda_function.health_check.arn
}

resource "aws_lambda_permission" "health_check_eventbridge" {
  statement_id  = "AllowEventBridgeHealthCheck"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_check.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.health_check.arn
}

# ── Backup Lambda (daily at 02:00 UTC) ────────────────────────────────────────
resource "aws_lambda_function" "backup" {
  function_name    = "wp-platform-backup"
  filename         = "${path.module}/scheduled_tasks.zip"
  source_code_hash = filebase64sha256("${path.module}/scheduled_tasks.zip")
  handler          = "scheduled_tasks.backup"
  runtime          = "python3.12"
  role             = aws_iam_role.scheduled_lambda.arn
  timeout          = 300

  environment {
    variables = {
      SITES_TABLE     = aws_dynamodb_table.sites.name
      BACKUPS_TABLE   = aws_dynamodb_table.backups.name
      ALERT_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }

  tags = { Name = "wp-platform-backup" }
}

resource "aws_cloudwatch_log_group" "backup" {
  name              = "/aws/lambda/${aws_lambda_function.backup.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_event_rule" "backup" {
  name                = "wp-platform-daily-backup"
  schedule_expression = "cron(0 2 * * ? *)"
  description         = "Trigger daily backup at 02:00 UTC"
}

resource "aws_cloudwatch_event_target" "backup" {
  rule      = aws_cloudwatch_event_rule.backup.name
  target_id = "backup-lambda"
  arn       = aws_lambda_function.backup.arn
}

resource "aws_lambda_permission" "backup_eventbridge" {
  statement_id  = "AllowEventBridgeBackup"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.backup.arn
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "health_check_lambda_arn" {
  value = aws_lambda_function.health_check.arn
}

output "backup_lambda_arn" {
  value = aws_lambda_function.backup.arn
}
