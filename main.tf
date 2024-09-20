terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Allows all versions in 3.x.x
    }
  }
}


provider "azurerm" {
  subscription_id = "d055dd42-c99f-4996-a41c-c5eeaae843f3"
  features {}
}


# Resource Group
resource "azurerm_resource_group" "peer-rg" {
  name     = "myResourceGroup"
  location = "East US"
}

# Virtual Network 1
resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.peer-rg.location
  resource_group_name = azurerm_resource_group.peer-rg.name
}

# Subnet in VNet1
resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.peer-rg.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP for VM1
resource "azurerm_public_ip" "public_ip1" {
  name                = "publicIP1"
  location            = azurerm_resource_group.peer-rg.location
  resource_group_name = azurerm_resource_group.peer-rg.name
  allocation_method   = "Static"     # Set to Static for Standard SKU
  sku                 = "Standard" # Use Standard SKU to match the load balancer
}

# Network Interface for VM1
resource "azurerm_network_interface" "nic1" {
  name                = "nic1"
  location            = azurerm_resource_group.peer-rg.location
  resource_group_name = azurerm_resource_group.peer-rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip1.id
  }
}

# Virtual Network 2
resource "azurerm_virtual_network" "vnet2" {
  name                = "vnet2"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.peer-rg.location
  resource_group_name = azurerm_resource_group.peer-rg.name
}

# Subnet in VNet2
resource "azurerm_subnet" "subnet2" {
  name                 = "subnet2"
  resource_group_name  = azurerm_resource_group.peer-rg.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.1.1.0/24"]
}

# Public IP for VM2
resource "azurerm_public_ip" "public_ip2" {
  name                = "publicIP2"
  location            = azurerm_resource_group.peer-rg.location
  resource_group_name = azurerm_resource_group.peer-rg.name
  allocation_method   = "Static"     # Set to Static for Standard SKU
  sku                 = "Standard" # Use Standard SKU to match the load balancer
}

# Network Interface for VM2
resource "azurerm_network_interface" "nic2" {
  name                = "nic2"
  location            = azurerm_resource_group.peer-rg.location
  resource_group_name = azurerm_resource_group.peer-rg.name

  ip_configuration {
    name                          = "ipconfig2"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip2.id
  }
}

# Create Network Security Group for VMs (Allow HTTP and SSH)
resource "azurerm_network_security_group" "nsg" {
  name                = "example-nsg"
  location            = azurerm_resource_group.peer-rg.location
  resource_group_name = azurerm_resource_group.peer-rg.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with Network Interface for VM1
resource "azurerm_network_interface_security_group_association" "nsg_assoc_vm1" {
  network_interface_id      = azurerm_network_interface.nic1.id
  network_security_group_id = azurerm_network_security_group.nsg.id

  depends_on = [
    azurerm_network_interface.nic1,
    azurerm_network_security_group.nsg
  ]
}

# Associate NSG with Network Interface for VM2
resource "azurerm_network_interface_security_group_association" "nsg_assoc_vm2" {
  network_interface_id      = azurerm_network_interface.nic2.id
  network_security_group_id = azurerm_network_security_group.nsg.id

  depends_on = [
    azurerm_network_interface.nic2,
    azurerm_network_security_group.nsg
  ]
}



# Virtual Machine 1
resource "azurerm_linux_virtual_machine" "peer-1-vm" {
  name                  = "peer-vm-1"
  location              = azurerm_resource_group.peer-rg.location
  resource_group_name   = azurerm_resource_group.peer-rg.name
  network_interface_ids = [azurerm_network_interface.nic1.id]
  size                  = "Standard_DS1_v2"

  admin_username = "alam"
  admin_password = "Ahtashamalam@123" # Replace with your own password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "alam"
  disable_password_authentication = false
}

# Virtual Machine 1
resource "azurerm_linux_virtual_machine" "peer-2-vm" {
  name                  = "peer-vm-2"
  location              = azurerm_resource_group.peer-rg.location
  resource_group_name   = azurerm_resource_group.peer-rg.name
  network_interface_ids = [azurerm_network_interface.nic2.id]
  size                  = "Standard_DS1_v2"

  admin_username = "alam"
  admin_password = "Ahtashamalam@123" # Replace with your own password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "alam"
  disable_password_authentication = false
}


# VNet Peering from VNet1 to VNet2
resource "azurerm_virtual_network_peering" "vnet1_to_vnet2" {
  name                         = "vnet1-to-vnet2"
  resource_group_name          = azurerm_resource_group.peer-rg.name
  virtual_network_name         = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet2.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

# VNet Peering from VNet2 to VNet1
resource "azurerm_virtual_network_peering" "vnet2_to_vnet1" {
  name                         = "vnet2-to-vnet1"
  resource_group_name          = azurerm_resource_group.peer-rg.name
  virtual_network_name         = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet1.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}
