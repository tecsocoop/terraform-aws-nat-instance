output "network_interface_id" {
  description = "Network interface id of the NAT instance"
  value       = aws_network_interface.nat_instance.id
}

output "instance_id" {
  description = "NAT instance id (use with SSM Session Manager)"
  value       = aws_instance.nat_instance.id
}
