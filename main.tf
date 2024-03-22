# Resource Group
data "azurerm_resource_group" "rg" {
  #location = var.resource_group_location
  name     = var.resource_group_name
}

# HUB 
resource "azurerm_virtual_network" "vnet_hub" {
  name                = "vnet_hub"
  address_space       = ["10.0.0.0/23"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "vnet_hub_subnet_default" {
  name                 = "default"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = ["10.0.0.0/24"]
}

# SPOKE 1
resource "azurerm_virtual_network" "vnet_spoke1" {
  name                = "vnet_spoke1"
  address_space       = ["10.0.100.0/23"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "vnet_spoke1_subnet_default" {
  name                 = "default"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_spoke1.name
  address_prefixes     = ["10.0.100.0/24"]
}

# SPOKE 2
resource "azurerm_virtual_network" "vnet_spoke2" {
  name                = "vnet_spoke2"
  address_space       = ["10.0.200.0/23"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "vnet_spoke2_subnet_default" {
  name                 = "default"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet_spoke2.name
  address_prefixes     = ["10.0.200.0/24"]
}

# VNET peerings
#  -> hub - spoke1
resource "azurerm_virtual_network_peering" "vnet_peering_hub_spoke1" {
  name                      = "hub-spoke1"
  resource_group_name       = data.azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_hub.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_spoke1.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "vnet_peering_spoke1_hub" {
  name                      = "spoke1-hub"
  resource_group_name       = data.azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_spoke1.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_hub.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}


#  -> hub - spoke2
resource "azurerm_virtual_network_peering" "vnet_peering_hub_spoke2" {
  name                      = "hub-spoke2"
  resource_group_name       = data.azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_hub.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_spoke2.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "vnet_peering_spoke2_hub" {
  name                      = "hub-spoke2"
  resource_group_name       = data.azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet_spoke2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_hub.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

# Public IPs 
resource "azurerm_public_ip" "public_ip_hub" {
  name                = "public_ip_hub"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "public_ip_spoke1" {
  name                = "public_ip_spoke1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "public_ip_spoke2" {
  name                = "public_ip_spoke2"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Network Security Group for SSH
resource "azurerm_network_security_group" "nsg_vm" {
  name                = "nsg_vm"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network interfaces
# NIC Hub
resource "azurerm_network_interface" "nic_hub" {
  name                 = "nic_hub"
  location             = data.azurerm_resource_group.rg.location
  resource_group_name  = data.azurerm_resource_group.rg.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "nic_hub_configuration"
    subnet_id                     = azurerm_subnet.vnet_hub_subnet_default.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.4"
    public_ip_address_id          = azurerm_public_ip.public_ip_hub.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic_hub_nsg_vm" {
  network_interface_id      = azurerm_network_interface.nic_hub.id
  network_security_group_id = azurerm_network_security_group.nsg_vm.id
}

# NIC Spoke 1
resource "azurerm_network_interface" "nic_spoke1" {
  name                 = "nic_spoke1"
  location             = data.azurerm_resource_group.rg.location
  resource_group_name  = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nic_spoke1_configuration"
    subnet_id                     = azurerm_subnet.vnet_spoke1_subnet_default.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.100.4"
    public_ip_address_id          = azurerm_public_ip.public_ip_spoke1.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic_spoke1_nsg_vm" {
  network_interface_id      = azurerm_network_interface.nic_spoke1.id
  network_security_group_id = azurerm_network_security_group.nsg_vm.id
}

# NIC Spoke 2
resource "azurerm_network_interface" "nic_spoke2" {
  name                 = "nic_spoke2"
  location             = data.azurerm_resource_group.rg.location
  resource_group_name  = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "nic_spoke2_configuration"
    subnet_id                     = azurerm_subnet.vnet_spoke2_subnet_default.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.200.4"
    public_ip_address_id          = azurerm_public_ip.public_ip_spoke2.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic_spoke2_nsg_vm" {
  network_interface_id      = azurerm_network_interface.nic_spoke2.id
  network_security_group_id = azurerm_network_security_group.nsg_vm.id
}

# Virtual machines
# SSH keys
resource "azapi_resource_action" "ssh_public_key_gen" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}

resource "azapi_resource" "ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = "vm_ssh_keys"
  location  = data.azurerm_resource_group.rg.location
  parent_id = data.azurerm_resource_group.rg.id
}

#  vm for the Hub (router)
# Create virtual machine
resource "azurerm_linux_virtual_machine" "vm_hub" {
  name                  = "vm_hub"
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_hub.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "hubDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "87-gen2"
    version   = "latest"
  }

  admin_username = "azureuser"
  computer_name  = "vm-hub"  

  admin_ssh_key {    
    username   = "azureuser"
    public_key = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
  }
}

resource "azurerm_virtual_machine_extension" "vmext" {
    name                    = "hub-extension"

    virtual_machine_id   = azurerm_linux_virtual_machine.vm_hub.id
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.0"

    protected_settings = <<PROT
    {
        "script": "${base64encode(file(var.customize_hub_script))}"
    }
    PROT
}

#  vm for the spoke 1
resource "azurerm_linux_virtual_machine" "vm_spoke1" {
  name                  = "vm_spoke1"
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_spoke1.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "spoke1Disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "87-gen2"
    version   = "latest"
  }

  admin_username = "azureuser"
  computer_name  = "vm-spoke1"  

  admin_ssh_key {    
    username   = "azureuser"
    public_key = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
  }
}

#  vm for the spoke 2
resource "azurerm_linux_virtual_machine" "vm_spoke2" {
  name                  = "vm_spoke2"
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic_spoke2.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "spoke2Disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "87-gen2"
    version   = "latest"
  }

  admin_username = "azureuser"
  computer_name  = "vm-spoke2"  

  admin_ssh_key {    
    username   = "azureuser"
    public_key = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
  }
}

# Route table for spokes
# --> Spoke 1
resource "azurerm_route_table" "rt_spoke1" {
  name                = "rt_spoke1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  route {
    name                   = "to-spoke2"
    address_prefix         = azurerm_virtual_network.vnet_spoke2.address_space[0]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.nic_hub.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "spoke1_subnet_default_rt_spoke1" {
  subnet_id      = azurerm_subnet.vnet_spoke1_subnet_default.id
  route_table_id = azurerm_route_table.rt_spoke1.id
}


# Route table for spokes
# --> Spoke 2
resource "azurerm_route_table" "rt_spoke2" {
  name                = "rt_spoke2"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  route {
    name                   = "to-spoke1"
    address_prefix         = azurerm_virtual_network.vnet_spoke1.address_space[0]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.nic_hub.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "spoke2_subnet_default_rt_spoke2" {
  subnet_id      = azurerm_subnet.vnet_spoke2_subnet_default.id
  route_table_id = azurerm_route_table.rt_spoke2.id
}