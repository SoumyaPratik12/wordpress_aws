# ── IAM role for the API Lambda ───────────────────────────────────────────────
resource "aws_iam_role" "api_lambda" {
  name = "wp-platform-api-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = { Name = "wp-platform-api-lambda" }
}

resource "aws_iam_role_policy" "api_lambda_policy" {
  name = "wp-platform-api-lambda-policy"
  role = aws_iam_role.api_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem",
          "dynamodb:DeleteItem", "dynamodb:Query", "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.sites.arn,
          "${aws_dynamodb_table.sites.arn}/index/*",
          aws_dynamodb_table.backups.arn,
          "${aws_dynamodb_table.backups.arn}/index/*",
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ── Lambda function ───────────────────────────────────────────────────────────
resource "aws_lambda_function" "api" {
  function_name    = "wp-platform-api"
  filename         = "${path.module}/api_handler.zip"
  source_code_hash = filebase64sha256("${path.module}/api_handler.zip")
  handler          = "handler.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.api_lambda.arn
  timeout          = 30

  environment {
    variables = {
      SITES_TABLE   = aws_dynamodb_table.sites.name
      BACKUPS_TABLE = aws_dynamodb_table.backups.name
    }
  }

  tags = { Name = "wp-platform-api" }
}

resource "aws_cloudwatch_log_group" "api_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.api.function_name}"
  retention_in_days = 14
}

# ── API Gateway v2 (HTTP API) ─────────────────────────────────────────────────
resource "aws_apigatewayv2_api" "wp_platform" {
  name          = "wp-platform-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.wp_platform.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-authorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.web_client.id]
    issuer   = "https://cognito-idp.ap-south-1.amazonaws.com/${aws_cognito_user_pool.wp_platform.id}"
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.wp_platform.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default" {
  api_id             = aws_apigatewayv2_api.wp_platform.id
  route_key          = "$default"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
  authorization_type = "JWT"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.wp_platform.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format          = "$context.requestId $context.status $context.routeKey $context.integrationErrorMessage"
  }
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/apigateway/wp-platform-api"
  retention_in_days = 14
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.wp_platform.execution_arn}/*/*"
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "api_endpoint" {
  value = aws_apigatewayv2_api.wp_platform.api_endpoint
}

output "api_id" {
  value = aws_apigatewayv2_api.wp_platform.id
}
