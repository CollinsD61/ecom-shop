output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (use this as CNAME target in Cloudflare)"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (use for cache invalidation)"
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID"
  value       = aws_cloudfront_distribution.frontend.hosted_zone_id
}
