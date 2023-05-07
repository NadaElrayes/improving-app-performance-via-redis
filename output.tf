output "db_endpoint" {
  value = aws_db_instance.postgres_db.endpoint
}

output "instance_id" {
  value = module.ec2-app.id
}

output "public_ip" {
  value       = module.ec2-app.public_ip
  description = "App EC2 IP"
}