output "ssh_private_key" {
  value = tls_private_key.ssh_key.private_key_pem
}

output "public_ip" {
  value = aws_instance.bastion.public_ip
}
