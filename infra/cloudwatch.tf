# ── CloudWatch Alarms ─────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "api_errors" {
  alarm_name          = "wp-platform-api-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "API Lambda error rate is high"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  dimensions          = { FunctionName = aws_lambda_function.api.function_name }
}

resource "aws_cloudwatch_metric_alarm" "api_gw_5xx" {
  alarm_name          = "wp-platform-api-gw-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "API Gateway 5xx error rate is high"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    ApiId = aws_apigatewayv2_api.wp_platform.id
    Stage = "$default"
  }
}

resource "aws_cloudwatch_metric_alarm" "health_check_errors" {
  alarm_name          = "wp-platform-health-check-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Health check Lambda is failing"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions          = { FunctionName = aws_lambda_function.health_check.function_name }
}

resource "aws_cloudwatch_metric_alarm" "backup_errors" {
  alarm_name          = "wp-platform-backup-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 86400
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Daily backup Lambda is failing"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions          = { FunctionName = aws_lambda_function.backup.function_name }
}

resource "aws_cloudwatch_metric_alarm" "deploy_failures" {
  alarm_name          = "wp-platform-deploy-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "WordPress deployment workflow failed"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions          = { StateMachineArn = aws_sfn_state_machine.deploy_wordpress.arn }
}

# ── CloudWatch Dashboard ──────────────────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "wp_platform" {
  dashboard_name = "wp-platform"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# WP Platform — Operations Dashboard"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 8
        height = 6
        properties = {
          title  = "API Lambda — Invocations & Errors"
          region = "ap-south-1"
          period = 300
          view   = "timeSeries"
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.api.function_name, { stat = "Sum", label = "Invocations" }],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.api.function_name, { stat = "Sum", label = "Errors", color = "#d62728" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 1
        width  = 8
        height = 6
        properties = {
          title  = "API Gateway — Latency & 5xx"
          region = "ap-south-1"
          period = 300
          view   = "timeSeries"
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiId", aws_apigatewayv2_api.wp_platform.id, "Stage", "$default", { stat = "p99", label = "p99 Latency (ms)" }],
            ["AWS/ApiGateway", "5XXError", "ApiId", aws_apigatewayv2_api.wp_platform.id, "Stage", "$default", { stat = "Sum", label = "5xx Errors", color = "#d62728" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 1
        width  = 8
        height = 6
        properties = {
          title  = "Deploy Workflow — Executions"
          region = "ap-south-1"
          period = 300
          view   = "timeSeries"
          metrics = [
            ["AWS/States", "ExecutionsStarted", "StateMachineArn", aws_sfn_state_machine.deploy_wordpress.arn, { stat = "Sum", label = "Started" }],
            ["AWS/States", "ExecutionsSucceeded", "StateMachineArn", aws_sfn_state_machine.deploy_wordpress.arn, { stat = "Sum", label = "Succeeded", color = "#2ca02c" }],
            ["AWS/States", "ExecutionsFailed", "StateMachineArn", aws_sfn_state_machine.deploy_wordpress.arn, { stat = "Sum", label = "Failed", color = "#d62728" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 8
        height = 6
        properties = {
          title  = "Health Check Lambda"
          region = "ap-south-1"
          period = 300
          view   = "timeSeries"
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.health_check.function_name, { stat = "Sum" }],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.health_check.function_name, { stat = "Sum", color = "#d62728" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 7
        width  = 8
        height = 6
        properties = {
          title  = "Backup Lambda"
          region = "ap-south-1"
          period = 86400
          view   = "timeSeries"
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.backup.function_name, { stat = "Sum" }],
            ["AWS/Lambda", "Errors", "FunctionName", aws_lambda_function.backup.function_name, { stat = "Sum", color = "#d62728" }],
            ["AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.backup.function_name, { stat = "Average", label = "Avg Duration (ms)" }],
          ]
        }
      },
      {
        type   = "alarm"
        x      = 16
        y      = 7
        width  = 8
        height = 6
        properties = {
          title = "Active Alarms"
          alarms = [
            aws_cloudwatch_metric_alarm.api_errors.arn,
            aws_cloudwatch_metric_alarm.api_gw_5xx.arn,
            aws_cloudwatch_metric_alarm.health_check_errors.arn,
            aws_cloudwatch_metric_alarm.backup_errors.arn,
            aws_cloudwatch_metric_alarm.deploy_failures.arn,
          ]
        }
      }
    ]
  })
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "cloudwatch_dashboard_url" {
  value = "https://ap-south-1.console.aws.amazon.com/cloudwatch/home?region=ap-south-1#dashboards:name=wp-platform"
}
