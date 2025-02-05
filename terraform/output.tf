# output "private_ip" {
#   value = module.ec2.private_instance_private_ips
# }
# output "public_ip" {
#   value = module.ec2.private_instance_public_ips
# }

# output "nat_ip" {
#   value = aws_nat_gateway.nat_gw.public_ip
# }

output "Bastion_host_IP" {
  value = aws_eip.bastion_host_eip.public_ip
}

output "nginx_instance" {
  value = aws_instance.nginx_instance.public_ip
}

output "rtsp" {
  value = aws_instance.rtsp_to_web_instance.public_ip
}