output "resource_group_name" {
  value = azurerm_resource_group.rg_teste.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.terraform_vm_teste.public_ip_address
}

output "tls_private_key" {
  value     = tls_private_key.key_ssh.private_key_pem
  sensitive = true
}

output "vnet_subnets" {
 value = module.network.vnet_subnets
}

output "vnet_id" {
 value = module.network.vnet_id
}

output "nginx_private_ip" {
   value = azurerm_linux_virtual_machine.nginx.private_ip_address
}

output "nginx_public_ip" {
   value = azurerm_linux_virtual_machine.nginx.public_ip_address
}