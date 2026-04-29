output "external_dns_role_arn" {
  description = "IAM role ARN for External DNS"
  value       = aws_iam_role.external_dns.arn
}
