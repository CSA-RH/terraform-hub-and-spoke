output "vm_ssh_public_key" {
  value = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
}

output "vm_ssh_private_key" {
  value = jsondecode(azapi_resource_action.ssh_public_key_gen.output).privateKey
}

output "public_ip_hub" {
    value = azurerm_public_ip.public_ip_hub.ip_address
}

output "public_ip_spoke1" {
    value = azurerm_public_ip.public_ip_spoke1.ip_address
}

output "public_ip_spoke2" {
    value = azurerm_public_ip.public_ip_spoke2.ip_address
}