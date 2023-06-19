# Configure the Azure provider

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg_teste" {
  name     = "myTFResourceGroup"
  location = "westus2"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  location            = azurerm_resource_group.rg_teste.location
  resource_group_name = azurerm_resource_group.rg_teste.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "terraform_subnet_teste" {
  name                 = "subnetTeste"
  resource_group_name  = azurerm_resource_group.rg_teste.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "terraform_public_ip_teste" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg_teste.location
  resource_group_name = azurerm_resource_group.rg_teste.name
  allocation_method   = "Dynamic"

  depends_on = [azurerm_resource_group.rg_teste]
}

resource "azurerm_network_security_group" "terraform_nsg_teste" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.rg_teste.location
  resource_group_name = azurerm_resource_group.rg_teste.name

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

resource "azurerm_network_interface" "terraform_nic_teste" {
  name                = "myNIC"
  location            = azurerm_resource_group.rg_teste.location
  resource_group_name = azurerm_resource_group.rg_teste.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.terraform_subnet_teste.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terraform_public_ip_teste.id
  }
}

resource "azurerm_network_interface_security_group_association" "azurerm_isga" {
  network_interface_id      = azurerm_network_interface.terraform_nic_teste.id
  network_security_group_id = azurerm_network_security_group.terraform_nsg_teste.id
}

resource "random_id" "random_id" {
  keepers = {
    resource_group = azurerm_resource_group.rg_teste.name
  }

  byte_length = 8
}

resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg_teste.location
  resource_group_name      = azurerm_resource_group.rg_teste.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "tls_private_key" "key_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "terraform_vm_teste" {
  name                  = "myVM"
  location              = azurerm_resource_group.rg_testeg.location
  resource_group_name   = azurerm_resource_group.rg_teste.name
  network_interface_ids = [azurerm_network_interface.terraform_nic_teste.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "nginx"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  computer_name                   = "nginx"
  admin_username                  = "azureuser"
  disable_password_authentication = false

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.key_ssh.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
}

resource "azurerm_network_interface" "webserver" {
  name = "nginx-interface"
  location = azurerm_resource_group.rg_teste.location
  resource_group_name = azurerm_resource_group.rg_teste.name

  ip_configuration {
    name = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id = module.network.vnet_subnets[0]
    public_ip_address_id = azurerm_public_ip.terraform_public_ip_teste.id
  }

  depends_on = [azurerm_resource_group.rg_teste]
}