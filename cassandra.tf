# cassandra.tf 
# locals
locals {
  cassandra_node_count = var.cassandra_node_count
  cassandra_nodes = {
    for i in range(local.cassandra_node_count) :
    "cassandra-${i + 1}" => {
      index = i
    }
  }

  seed_nodes     = join(",", [for key, nic in azurerm_network_interface.cassandra : nic.ip_configuration[0].private_ip_address if tonumber(trimprefix(key, "cassandra-")) % 2 != 0])
  seed_node_list = [for s in split(",", "${local.seed_nodes}") : trimspace(s)]
}

# -----------------------------------------------------------
# Availability Set for fault domain distribution
# -----------------------------------------------------------
resource "azurerm_availability_set" "cassandra" {
  name                         = "${var.project}-cassandra-avset"
  location                     = local.resource_group_location
  resource_group_name          = local.resource_group_name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 3
  managed                      = true
}

# -----------------------------------------------------------
# Network Interfaces
# -----------------------------------------------------------
resource "azurerm_network_interface" "cassandra" {
  for_each = local.cassandra_nodes

  name                = "${var.project}-nic-${each.key}"
  location            = local.resource_group_location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnets["private"].id
    private_ip_address_allocation = "Dynamic"
  }
}

# -----------------------------------------------------------
# Associate NIC with Cassandra NSG
# -----------------------------------------------------------
resource "azurerm_network_interface_security_group_association" "cassandra" {
  for_each = local.cassandra_nodes

  network_interface_id      = azurerm_network_interface.cassandra[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg["private"].id
}

# -----------------------------------------------------------
resource "azurerm_linux_virtual_machine" "cassandra" {
  for_each = local.cassandra_nodes

  name                            = "${var.project}-${each.key}"
  location                        = local.resource_group_location
  resource_group_name             = local.resource_group_name
  size                            = var.cassandra_vm_size
  admin_username                  = var.cassandra_admin_username
  availability_set_id             = azurerm_availability_set.cassandra.id
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.cassandra[each.key].id
  ]

  admin_password = var.cassandra_admin_password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # Data disk for Cassandra data
  # Attached below separately

  custom_data = base64encode(templatefile("${path.module}/install-cassandra.sh", {
    seeds        = local.seed_nodes
    node_index   = each.value.index
    cluster_name = "${var.project}-prod-cluster"
  }))

  tags = {
    environment = var.environment
    managed-by  = "terraform"
    service     = "cassandra"
  }
}

# -----------------------------------------------------------
# Managed Data Disks (separate from OS for Cassandra data)
# -----------------------------------------------------------
resource "azurerm_managed_disk" "cassandra" {
  for_each = local.cassandra_nodes

  name                 = "${var.project}-${each.key}-data-disk"
  location             = local.resource_group_location
  resource_group_name  = local.resource_group_name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.cassandra_data_disk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "cassandra" {
  for_each = local.cassandra_nodes

  managed_disk_id    = azurerm_managed_disk.cassandra[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.cassandra[each.key].id
  lun                = 10
  caching            = "ReadWrite"
}