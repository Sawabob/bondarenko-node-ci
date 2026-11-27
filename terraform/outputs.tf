output "instance_ip" {
  description = "Public IPv4 address for the EC2_HOST GitHub Actions secret."
  value       = aws_instance.web.public_ip
}

output "instance_id" {
  description = "EC2 instance ID for reading the authenticated system log."
  value       = aws_instance.web.id
}

output "security_group_id" {
  description = "Security group ID for checking cleanup in AWS."
  value       = aws_security_group.web.id
}
