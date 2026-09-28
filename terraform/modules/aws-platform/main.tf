# $0 Azure platform: free-tier B1s VM running k3s (single-node Kubernetes).
# No AKS node-pool bills (control plane is free, nodes are not).

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

locals { name = "${var.name_prefix}-${var.environment}" }

resource "azurerm_resource_group" "platform" {
  name     = "${local.name}-rg"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "platform" {
  name                = "${local.name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
}

resource "azurerm_subnet" "portfolio" {
  name                 = "portfolio"
  resource_group_name  = azurerm_resource_group.platform.name
  virtual_network_name = azurerm_virtual_network.platform.name
  address_prefixes     = [var.subnet_cidr]
}

resource "azurerm_network_security_group" "portfolio" {
  name                = "${local.name}-nsg"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "portfolio" {
  subnet_id                 = azurerm_subnet.portfolio.id
  network_security_group_id = azurerm_network_security_group.portfolio.id
}

# Basic SKU public IP ($0). Static so DNS stays stable across reboots.
resource "azurerm_public_ip" "portfolio" {
  name                = "${local.name}-pip"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  allocation_method   = "Static"
  sku                 = "Basic"
  domain_name_label   = replace(local.name, "_", "-")
  tags                = var.tags
}

resource "azurerm_network_interface" "portfolio" {
  name                = "${local.name}-nic"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.portfolio.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.portfolio.id
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "portfolio" {
  name                  = "${local.name}-vm"
  location              = azurerm_resource_group.platform.location
  resource_group_name   = azurerm_resource_group.platform.name
  size                  = "Standard_B1s" # free tier: 750 hrs/month (12 months)
  admin_username        = var.vm_admin_username
  network_interface_ids = [azurerm_network_interface.portfolio.id]

  admin_password                  = var.vm_admin_password
  disable_password_authentication = false

  # custom_data is ForceNew: a new image tag automatically replaces the VM.
  custom_data = base64encode(templatefile("${path.module}/templates/portfolio-user-data.sh.tpl", {
    image_repository = var.image_repository
    image_tag        = var.image_tag
  }))

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  tags = var.tags
}
