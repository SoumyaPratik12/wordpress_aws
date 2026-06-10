# ── SNS topic for all platform alerts ────────────────────────────────────────
resource "aws_sns_topic" "alerts" {
  name = "wp-platform-alerts"
  tags = { Name = "wp-platform-alerts" }
}

# ── SES — verified sender identity ───────────────────────────────────────────
resource "aws_ses_email_identity" "sender" {
  email = "soumya.pratik2@gmail.com"
}

# ── Lambda: SNS → SES forwarder (no email confirmation needed) ────────────────
resource "aws_iam_role" "sns_forwarder" {
  name = "wp-platform-sns-forwarder"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "sns_forwarder_policy" {
  name = "wp-platform-sns-forwarder-policy"
  role = aws_iam_role.sns_forwarder.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function" "sns_forwarder" {
  function_name    = "wp-platform-sns-forwarder"
  filename         = "${path.module}/sns_to_ses.zip"
  source_code_hash = filebase64sha256("${path.module}/sns_to_ses.zip")
  handler          = "sns_to_ses.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.sns_forwarder.arn
  timeout          = 30

  environment {
    variables = { ALERT_EMAIL = "soumya.pratik2@gmail.com" }
  }

  tags = { Name = "wp-platform-sns-forwarder" }
}

resource "aws_cloudwatch_log_group" "sns_forwarder" {
  name              = "/aws/lambda/${aws_lambda_function.sns_forwarder.function_name}"
  retention_in_days = 14
}

# Allow SNS to invoke the forwarder Lambda
resource "aws_lambda_permission" "sns_invoke_forwarder" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_forwarder.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}

# Lambda subscription — no email confirmation required
resource "aws_sns_topic_subscription" "lambda_forwarder" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.sns_forwarder.arn
}

# ── IAM policy so other Lambdas can send SES emails directly ─────────────────
resource "aws_iam_policy" "ses_send" {
  name = "wp-platform-ses-send"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ses:SendEmail", "ses:SendRawEmail"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "scheduled_ses" {
  role       = aws_iam_role.scheduled_lambda.name
  policy_arn = aws_iam_policy.ses_send.arn
}

resource "aws_iam_role_policy_attachment" "deploy_ses" {
  role       = aws_iam_role.deploy_lambda.name
  policy_arn = aws_iam_policy.ses_send.arn
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "sns_alert_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "ses_sender_identity" {
  value = aws_ses_email_identity.sender.email
}
