# Network Interface for Elasticsearch VM (Private only)
resource "azurerm_network_interface" "elasticsearch" {
  name                = "${var.project}-elasticsearch-nic"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.existing_vnet_name == "" ? azurerm_subnet.subnets["private"].id : data.azurerm_subnet.existing["private"].id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = var.environment
    managed-by  = "terraform"
  }

  depends_on = [
    azurerm_virtual_network.prod,
    azurerm_subnet_nat_gateway_association.this,
  ]
}

# Elasticsearch Installation Script
locals {
  elasticsearch_script = base64encode(templatefile("${path.module}/install-elasticsearch.sh", {
    elasticsearch_password = var.elasticsearch_admin_password
    elasticsearch_version  = var.elasticsearch_version
  }))
}

# Virtual Machine for Elasticsearch (Private Network)
resource "azurerm_linux_virtual_machine" "elasticsearch" {
  name                = "${var.project}-elasticsearch-vm"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name
  size                = var.elasticsearch_vm_size
  admin_username      = var.elasticsearch_admin_username

  # Disable password authentication and use SSH keys for better security
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.elasticsearch.id,
  ]

  admin_password = var.elasticsearch_admin_password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.elasticsearch_os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = local.elasticsearch_script

  tags = {
    environment = var.environment
    managed-by  = "terraform"
    service     = "elasticsearch"
  }

  depends_on = [azurerm_virtual_network.prod]
}