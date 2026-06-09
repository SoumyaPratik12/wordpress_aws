# ── Sites table ───────────────────────────────────────────────────────────────
resource "aws_dynamodb_table" "sites" {
  name         = "Sites"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "siteId"

  attribute {
    name = "siteId"
    type = "S"
  }

  attribute {
    name = "ownerId"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  global_secondary_index {
    name            = "OwnerIndex"
    hash_key        = "ownerId"
    range_key       = "siteId"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "StatusIndex"
    hash_key        = "status"
    range_key       = "siteId"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "wp-platform-sites"
  }
}

# ── Backups table ─────────────────────────────────────────────────────────────
resource "aws_dynamodb_table" "backups" {
  name         = "Backups"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "backupId"
  range_key    = "siteId"

  attribute {
    name = "backupId"
    type = "S"
  }

  attribute {
    name = "siteId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  global_secondary_index {
    name            = "SiteBackupsIndex"
    hash_key        = "siteId"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  tags = {
    Name = "wp-platform-backups"
  }
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "dynamodb_sites_table_name" {
  value = aws_dynamodb_table.sites.name
}

output "dynamodb_sites_table_arn" {
  value = aws_dynamodb_table.sites.arn
}

output "dynamodb_backups_table_name" {
  value = aws_dynamodb_table.backups.name
}

output "dynamodb_backups_table_arn" {
  value = aws_dynamodb_table.backups.arn
}
