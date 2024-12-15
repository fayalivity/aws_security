output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "app_private_ip" {
  value = aws_instance.app.private_ip
}

output "alb_dns" {
  value = aws_lb.alb.dns_name
}

output "vpc_id" {
  value = aws_vpc.main_vpc.id
}