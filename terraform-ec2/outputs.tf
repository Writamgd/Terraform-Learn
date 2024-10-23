output "public_ip_address" {
    value = module.ec2_instance.public_ip_address
  
}

output "instance_id" {
    value = module.ec2_instance.instance_id
  
}
