# ── IAM role shared by all deploy-workflow Lambdas ────────────────────────────
resource "aws_iam_role" "deploy_lambda" {
  name = "wp-platform-deploy-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "deploy_lambda_policy" {
  name = "wp-platform-deploy-lambda-policy"
  role = aws_iam_role.deploy_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:UpdateItem"]
        Resource = aws_dynamodb_table.sites.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ── Deploy workflow Lambdas ───────────────────────────────────────────────────
locals {
  deploy_handlers = {
    provision_infrastructure = "deploy_wordpress.provision_infrastructure"
    install_wordpress        = "deploy_wordpress.install_wordpress"
    configure_dns            = "deploy_wordpress.configure_dns"
    run_health_check         = "deploy_wordpress.run_health_check"
    notify_complete          = "deploy_wordpress.notify_complete"
  }
}

resource "aws_lambda_function" "deploy" {
  for_each = local.deploy_handlers

  function_name    = "wp-platform-${replace(each.key, "_", "-")}"
  filename         = "${path.module}/deploy_wordpress.zip"
  source_code_hash = filebase64sha256("${path.module}/deploy_wordpress.zip")
  handler          = each.value
  runtime          = "python3.12"
  role             = aws_iam_role.deploy_lambda.arn
  timeout          = 60

  environment {
    variables = { SITES_TABLE = aws_dynamodb_table.sites.name }
  }

  tags = { Name = "wp-platform-${each.key}" }
}

resource "aws_cloudwatch_log_group" "deploy_lambda" {
  for_each          = local.deploy_handlers
  name              = "/aws/lambda/wp-platform-${replace(each.key, "_", "-")}"
  retention_in_days = 14
}

# ── IAM role for Step Functions ───────────────────────────────────────────────
resource "aws_iam_role" "step_functions" {
  name = "wp-platform-step-functions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "step_functions_policy" {
  name = "wp-platform-step-functions-policy"
  role = aws_iam_role.step_functions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = [for fn in aws_lambda_function.deploy : fn.arn]
    }]
  })
}

# ── State machine definition ──────────────────────────────────────────────────
resource "aws_sfn_state_machine" "deploy_wordpress" {
  name     = "wp-platform-deploy-wordpress"
  role_arn = aws_iam_role.step_functions.arn

  definition = jsonencode({
    Comment = "WordPress site deployment workflow"
    StartAt = "ProvisionInfrastructure"
    States = {
      ProvisionInfrastructure = {
        Type     = "Task"
        Resource = aws_lambda_function.deploy["provision_infrastructure"].arn
        Next     = "InstallWordPress"
        Retry = [{
          ErrorEquals     = ["States.TaskFailed"]
          IntervalSeconds = 5
          MaxAttempts     = 2
          BackoffRate     = 2
        }]
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "DeployFailed"
        }]
      }
      InstallWordPress = {
        Type     = "Task"
        Resource = aws_lambda_function.deploy["install_wordpress"].arn
        Next     = "ConfigureDNS"
        Retry = [{
          ErrorEquals     = ["States.TaskFailed"]
          IntervalSeconds = 10
          MaxAttempts     = 3
          BackoffRate     = 2
        }]
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "DeployFailed"
        }]
      }
      ConfigureDNS = {
        Type     = "Task"
        Resource = aws_lambda_function.deploy["configure_dns"].arn
        Next     = "RunHealthCheck"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "DeployFailed"
        }]
      }
      RunHealthCheck = {
        Type     = "Task"
        Resource = aws_lambda_function.deploy["run_health_check"].arn
        Next     = "NotifyComplete"
        Retry = [{
          ErrorEquals     = ["States.TaskFailed"]
          IntervalSeconds = 15
          MaxAttempts     = 3
          BackoffRate     = 1.5
        }]
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "DeployFailed"
        }]
      }
      NotifyComplete = {
        Type     = "Task"
        Resource = aws_lambda_function.deploy["notify_complete"].arn
        End      = true
      }
      DeployFailed = {
        Type  = "Fail"
        Error = "DeploymentFailed"
        Cause = "One or more deployment steps failed. Check CloudWatch logs."
      }
    }
  })

  tags = { Name = "wp-platform-deploy-wordpress" }
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "step_functions_arn" {
  value = aws_sfn_state_machine.deploy_wordpress.arn
}
