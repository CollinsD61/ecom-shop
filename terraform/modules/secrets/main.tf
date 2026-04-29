# ──────────────────────────────────────────────
# Shared RDS Secret: /ecom/{env}/shared/rds
# ──────────────────────────────────────────────

resource "aws_secretsmanager_secret" "shared_rds" {
  name                    = "/ecom/${var.env}/shared/rds"
  description             = "Shared RDS connection info for ${var.env}"
  recovery_window_in_days = var.env == "prod" ? 7 : 0

  tags = {
    Name        = "/ecom/${var.env}/shared/rds"
    Environment = var.env
  }
}

resource "aws_secretsmanager_secret_version" "shared_rds" {
  secret_id = aws_secretsmanager_secret.shared_rds.id

  secret_string = jsonencode({
    host     = var.db_host
    port     = var.db_port
    database = var.db_name
  })
}

# ──────────────────────────────────────────────
# Per-Service DB Secrets: /ecom/{env}/{service}/db
# ──────────────────────────────────────────────

resource "aws_secretsmanager_secret" "service_db" {
  for_each = toset(var.service_names)

  name                    = "/ecom/${var.env}/${each.value}/db"
  description             = "Database credentials for ${each.value} in ${var.env}"
  recovery_window_in_days = var.env == "prod" ? 7 : 0

  tags = {
    Name        = "/ecom/${var.env}/${each.value}/db"
    Environment = var.env
    Service     = each.value
  }
}

resource "aws_secretsmanager_secret_version" "service_db" {
  for_each  = toset(var.service_names)
  secret_id = aws_secretsmanager_secret.service_db[each.value].id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    jdbc_url = "jdbc:postgresql://${var.db_host}:${var.db_port}/${var.db_name}"
  })
}

