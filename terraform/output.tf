# output "nat_ip" {
#   value = aws_nat_gateway.nat_gw.public_ip
# }

output "public_ip" {
  value = {
    bastion = aws_eip.bastion_host_eip.public_ip
    nginx = aws_instance.nginx_instance.public_ip
    rtsp = aws_instance.rtsp_to_web_instance.public_ip
  }
}

output "private_ip" {
  value = {
    bastion = aws_instance.bastion_host_instance.private_ip
    nginx = aws_instance.nginx_instance.private_ip
    rtsp = aws_instance.rtsp_to_web_instance.private_ip
  }
}
