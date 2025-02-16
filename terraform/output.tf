output "public_ip" {
  value = {
    bastion = aws_instance.bastion_host_instance.public_ip
    nginx   = aws_instance.nginx_instance.public_ip
  }
}

output "private_ip" {
  value = {
    bastion = aws_instance.bastion_host_instance.private_ip
    nginx   = aws_instance.nginx_instance.private_ip
    rtsp    = aws_instance.rtsp_to_web_instance.private_ip
  }
}