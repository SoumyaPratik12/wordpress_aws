# ── Cognito User Pool ─────────────────────────────────────────────────────────
resource "aws_cognito_user_pool" "wp_platform" {
  name = "wp-platform-users"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 8
    require_uppercase                = true
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = false
    temporary_password_validity_days = 7
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  schema {
    name                = "role"
    attribute_data_type = "String"
    mutable             = true
    required            = false
    string_attribute_constraints {
      min_length = 1
      max_length = 50
    }
  }

  tags = {
    Name = "wp-platform-users"
  }
}

# ── User Pool Client (used by the React frontend) ─────────────────────────────
resource "aws_cognito_user_pool_client" "web_client" {
  name         = "wp-platform-web-client"
  user_pool_id = aws_cognito_user_pool.wp_platform.id

  generate_secret                      = false
  prevent_user_existence_errors        = "ENABLED"
  enable_token_revocation              = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
  ]

  callback_urls = ["http://localhost:3000/callback"]
  logout_urls   = ["http://localhost:3000/logout"]

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30
}

# ── User Pool Domain (hosted UI) ──────────────────────────────────────────────
resource "aws_cognito_user_pool_domain" "wp_platform" {
  domain       = "wp-platform-auth"
  user_pool_id = aws_cognito_user_pool.wp_platform.id
}

# ── Groups: Admin & Client ────────────────────────────────────────────────────
resource "aws_cognito_user_group" "admin" {
  name         = "Admin"
  user_pool_id = aws_cognito_user_pool.wp_platform.id
  description  = "Platform administrators"
  precedence   = 1
  role_arn     = aws_iam_role.cognito_admin.arn
}

resource "aws_cognito_user_group" "client" {
  name         = "Client"
  user_pool_id = aws_cognito_user_pool.wp_platform.id
  description  = "Regular clients / site owners"
  precedence   = 2
  role_arn     = aws_iam_role.cognito_client.arn
}

# ── IAM roles assumed by Cognito identity pool (future) ──────────────────────
data "aws_iam_policy_document" "cognito_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = [aws_cognito_user_pool.wp_platform.id]
    }
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["authenticated"]
    }
  }
}

resource "aws_iam_role" "cognito_admin" {
  name               = "wp-platform-cognito-admin"
  assume_role_policy = data.aws_iam_policy_document.cognito_assume.json
  tags               = { Name = "wp-platform-cognito-admin" }
}

resource "aws_iam_role" "cognito_client" {
  name               = "wp-platform-cognito-client"
  assume_role_policy = data.aws_iam_policy_document.cognito_assume.json
  tags               = { Name = "wp-platform-cognito-client" }
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.wp_platform.id
}

output "cognito_user_pool_arn" {
  value = aws_cognito_user_pool.wp_platform.arn
}

output "cognito_web_client_id" {
  value = aws_cognito_user_pool_client.web_client.id
}

output "cognito_domain" {
  value = "${aws_cognito_user_pool_domain.wp_platform.domain}.auth.ap-south-1.amazoncognito.com"
}
