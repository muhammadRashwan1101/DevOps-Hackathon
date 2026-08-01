output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.BackBenchers.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.BackBenchers.id
}

output "security_group_id" {
  description = "ID of the security group attached to the instance"
  value       = aws_security_group.BackBenchers_sg.id
}

output "ssh_connection_string" {
  description = "Ready-to-use SSH command to connect to the instance"
  value       = "ssh ubuntu@${aws_instance.BackBenchers.public_ip}"
}