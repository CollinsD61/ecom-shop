output "certificate_arn" {
  description = "ARN of the validated ACM wildcard certificate"
  value       = aws_acm_certificate_validation.wildcard.certificate_arn
}

output "certificate_domain" {
  description = "Domain covered by the certificate"
  value       = aws_acm_certificate.wildcard.domain_name
}

output "validation_options" {
  description = "DNS validation options (needed to create CNAME records in Cloudflare)"
  value = [for dvo in aws_acm_certificate.wildcard.domain_validation_options : {
    name  = dvo.resource_record_name
    type  = dvo.resource_record_type
    value = dvo.resource_record_value
  }]
}
