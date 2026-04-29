output "user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.arn
}

output "user_pool_endpoint" {
  description = "Endpoint of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.endpoint
}

output "app_client_id" {
  description = "ID of the Cognito App Client"
  value       = aws_cognito_user_pool_client.this.id
}

output "user_pool_domain" {
  description = "Cognito User Pool domain"
  value       = aws_cognito_user_pool_domain.this.domain
}

output "hosted_ui_login_url" {
  description = "Cognito Hosted UI login URL"
  value       = "https://${aws_cognito_user_pool_domain.this.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.this.id}&response_type=code&scope=openid+email+profile&redirect_uri=${var.callback_urls[0]}"
}

output "hosted_ui_signup_url" {
  description = "Cognito Hosted UI signup URL"
  value       = "https://${aws_cognito_user_pool_domain.this.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/signup?client_id=${aws_cognito_user_pool_client.this.id}&response_type=code&scope=openid+email+profile&redirect_uri=${var.callback_urls[0]}"
}

# ALB auth annotation for Helm values
output "alb_auth_idp_cognito_annotation" {
  description = "JSON annotation value for alb.ingress.kubernetes.io/auth-idp-cognito"
  value = jsonencode({
    userPoolARN      = aws_cognito_user_pool.this.arn
    userPoolClientID = aws_cognito_user_pool_client.this.id
    userPoolDomain   = aws_cognito_user_pool_domain.this.domain
  })
}
