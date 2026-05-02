output "instance_id" {
  description = "EC2 Instance ID of the k6 runner"
  value       = aws_instance.k6_runner.id
}

output "public_ip" {
  description = "Public IP of the k6 runner (if assigned)"
  value       = aws_instance.k6_runner.public_ip
}

output "private_ip" {
  description = "Private IP of the k6 runner"
  value       = aws_instance.k6_runner.private_ip
}

output "ssm_connect_command" {
  description = "Command to connect via SSM Session Manager (no SSH key needed)"
  value       = "aws ssm start-session --target ${aws_instance.k6_runner.id} --region ap-southeast-1"
}

output "security_group_id" {
  description = "Security Group ID of the k6 runner"
  value       = aws_security_group.k6_runner.id
}
