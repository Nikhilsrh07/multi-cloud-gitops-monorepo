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

resource "azurerm_subnet" "aks" {
  name                 = "aks"
  resource_group_name  = azurerm_resource_group.platform.name
  virtual_network_name = azurerm_virtual_network.platform.name
  address_prefixes     = [var.aks_subnet_cidr]
}

resource "azurerm_user_assigned_identity" "workload" {
  name                = "${local.name}-identity"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  tags                = var.tags
}

resource "azurerm_network_interface" "portfolio_vm" {
  count               = var.enable_vm ? 1 : 0
  name                = "${local.name}-vm-nic"
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.aks.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_kubernetes_cluster" "platform" {
  name                = local.name
  location            = azurerm_resource_group.platform.location
  resource_group_name = azurerm_resource_group.platform.name
  dns_prefix          = replace(local.name, "_", "-")
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name       = "system"
    node_count = var.node_count
    vm_size    = var.node_vm_size
    vnet_subnet_id = azurerm_subnet.aks.id
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.workload.id]
  }
  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "portfolio_vm" {
  count                 = var.enable_vm ? 1 : 0
  name                  = "${local.name}-vm"
  location              = azurerm_resource_group.platform.location
  resource_group_name   = azurerm_resource_group.platform.name
  size                  = var.vm_size
  admin_username        = var.vm_admin_username
  network_interface_ids = [azurerm_network_interface.portfolio_vm[0].id]
  admin_password        = var.vm_admin_password
  disable_password_authentication = false
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  tags = var.tags
}