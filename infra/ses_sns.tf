# ── SNS topic for all platform alerts ────────────────────────────────────────
resource "aws_sns_topic" "alerts" {
  name = "wp-platform-alerts"
  tags = { Name = "wp-platform-alerts" }
}

# Email subscription — replace with real ops address
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "soumya.pratik2@gmail.com"
}

# ── SES — verify the sender identity ─────────────────────────────────────────
resource "aws_ses_email_identity" "sender" {
  email = "soumya.pratik2@gmail.com"
}

# ── IAM policy so Lambdas can send SES emails ────────────────────────────────
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

# Attach to scheduled Lambda role (health check + backup notifications)
resource "aws_iam_role_policy_attachment" "scheduled_ses" {
  role       = aws_iam_role.scheduled_lambda.name
  policy_arn = aws_iam_policy.ses_send.arn
}

# Attach to deploy Lambda role (notify_complete step)
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
