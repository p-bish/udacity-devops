terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">=2.46.0"
    }
  }
}
provider "azurerm" {
  features {}
}
data "azurerm_subscription" "current" {}
data "azurerm_resource_group" "packerimgrg" {
  name = var.IMAGE_RG  
}
data "azurerm_image" "packerimg" {
  name = var.IMAGE_NAME
  resource_group_name = var.IMAGE_RG
} 

resource "azurerm_resource_group" "webrg" {
    name = "${var.RGNAME}"
    location = "East US 2"
    tags = {
      "Created by" = "${var.CREATOR}"
    }
}

resource "azurerm_network_security_group" "secgrp" {
  name = "webserver-security-group"
  location = azurerm_resource_group.webrg.location
  resource_group_name = azurerm_resource_group.webrg.name
  tags = {
    "Created by" = "${var.CREATOR}"
  }
}

resource "azurerm_network_security_rule" "denyinbound" {
  name = "DenyAllInternet"
  priority = 4096
  direction = "Inbound"
  access = "Deny"
  protocol = "*"
  source_port_range = "*"
  destination_port_range = "*"
  source_address_prefix = "Internet"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.webrg.name
  network_security_group_name = azurerm_network_security_group.secgrp.name
}

resource "azurerm_network_security_rule" "allowvnetout" {
  name = "AllowVnetOut"
  priority = 4095
  direction = "Outbound"
  access = "Allow"
  protocol = "*"
  source_port_range = "*"
  destination_port_range = "*"
  source_address_prefix = "VirtualNetwork"
  destination_address_prefix = "VirtualNetwork"
  resource_group_name = azurerm_resource_group.webrg.name
  network_security_group_name = azurerm_network_security_group.secgrp.name
}

resource "azurerm_network_security_rule" "allowvnetin" {
  name = "AllowVnetIn"
  priority = 4094
  direction = "Inbound"
  access = "Allow"
  protocol = "*"
  source_port_range = "*"
  destination_port_range = "*"
  source_address_prefix = "VirtualNetwork"
  destination_address_prefix = "VirtualNetwork"
  resource_group_name = azurerm_resource_group.webrg.name
  network_security_group_name = azurerm_network_security_group.secgrp.name
}

resource "azurerm_virtual_network" "webvnet" {
  name = "webserver-vnet"
  location = azurerm_resource_group.webrg.location
  resource_group_name = azurerm_resource_group.webrg.name
  address_space = ["10.0.0.0/24"]

  tags = {
    "Owner" = "${var.CREATOR}"
  }
}

resource "azurerm_subnet" "websubnet" {
    address_prefixes = ["10.0.0.0/24"]
    name = "webserver-snet"
    resource_group_name = azurerm_resource_group.webrg.name
    virtual_network_name = azurerm_virtual_network.webvnet.name
}

resource "azurerm_subnet_network_security_group_association" "nsgassoc" {
  subnet_id = azurerm_subnet.websubnet.id
  network_security_group_id = azurerm_network_security_group.secgrp.id
}

resource "azurerm_network_interface" "webnic" {
  count = "${var.VMCOUNT}"
  name = "web-nic-${count.index}"
  location = azurerm_resource_group.webrg.location
  resource_group_name = azurerm_resource_group.webrg.name

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.websubnet.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    "Created by" = "${var.CREATOR}"
  }
}

resource "azurerm_public_ip" "webpublicip" {
  name = "webpublicip"
  resource_group_name = azurerm_resource_group.webrg.name
  location = azurerm_resource_group.webrg.location
  allocation_method = "Dynamic"

  tags = {
    "Created by" = "${var.CREATOR}"
  }
}
resource "azurerm_lb" "weblb" {
  name = "WebLB"
  resource_group_name = azurerm_resource_group.webrg.name
  location = azurerm_resource_group.webrg.location

  frontend_ip_configuration {
    name = "WebLB-Public"
    public_ip_address_id = azurerm_public_ip.webpublicip.id
  }
  tags = {
    "Created by" = "${var.CREATOR}"
  }
}
resource "azurerm_lb_backend_address_pool" "weblbpool" {
  name = "WebLB-AddressPool"
  loadbalancer_id = azurerm_lb.weblb.id
}

resource "azurerm_availability_set" "webavailset" {
  name = "web-availset"
  resource_group_name = azurerm_resource_group.webrg.name
  location = azurerm_resource_group.webrg.location

  tags = {
    "Created by" = "${var.CREATOR}"
  }
}

resource "azurerm_managed_disk" "webvmmdisk" {
  count = "${var.VMCOUNT}"
  name = "webvm-manageddisk-${count.index}"
  resource_group_name = azurerm_resource_group.webrg.name
  location = azurerm_resource_group.webrg.location
  storage_account_type = "Standard_LRS"
  create_option = "Empty"
  disk_size_gb =  "16"

  tags = {
    "Created by" = "${var.CREATOR}"
  }
}

resource "azurerm_linux_virtual_machine" "webvm" {
  count = "${var.VMCOUNT}"
  name = "webvm-${count.index}"
  resource_group_name = azurerm_resource_group.webrg.name
  location = azurerm_resource_group.webrg.location
  network_interface_ids = [element(azurerm_network_interface.webnic.*.id, count.index)]
  availability_set_id = azurerm_availability_set.webavailset.id
  admin_username = "azureadmin"
  admin_password = "${var.ADMIN_PASS}"
  source_image_id = data.azurerm_image.packerimg.id
  disable_password_authentication = false
  size = "Standard_B1s"
  os_disk {
    storage_account_type = "Standard_LRS"
    caching = "ReadWrite"
  }
  tags = {
    "Created by" = "${var.CREATOR}"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "diskattach" {
  count = "${var.VMCOUNT}"
  managed_disk_id = azurerm_managed_disk.webvmmdisk[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.webvm[count.index].id
  lun = "2${count.index}"
  caching = "ReadWrite"
}

output "VMS" {
  value = ["${azurerm_linux_virtual_machine.webvm.*.admin_username}"]
  description = "Virtual Machine Admin Usernames"
}
output "PUBIP" {
  value = azurerm_public_ip.webpublicip.ip_address
  description = "Public IP of the Load Balancer"
}
output "PUBFQDN" {
  value = azurerm_public_ip.webpublicip.fqdn
  description = "FQDN of the Load Balancer"
}
output "VMIPS" {
  value = ["${azurerm_linux_virtual_machine.webvm.*.name}"]
  description = "Name of the generated Virtual machines"
}