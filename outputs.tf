output "web_alb_dns_name" {
  description = "Public DNS name of the external web ALB"
  value       = aws_lb.web.dns_name
}

output "backend_alb_dns_name" {
  description = "Internal DNS name of the backend ALB"
  value       = aws_lb.backend.dns_name
}

output "bastion_public_ip" {
  description = "Public IP of bastion host"
  value       = aws_instance.bastion.public_ip
}

output "db_password_parameter_name" {
  description = "SSM Parameter Store name for DB password"
  value       = aws_ssm_parameter.db_password.name
}
