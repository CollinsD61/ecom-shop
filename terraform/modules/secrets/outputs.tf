output "shared_rds_secret_arn" {
  description = "ARN of the shared RDS secret"
  value       = aws_secretsmanager_secret.shared_rds.arn
}

output "service_db_secret_arns" {
  description = "Map of service name to DB secret ARN"
  value       = { for k, v in aws_secretsmanager_secret.service_db : k => v.arn }
}
