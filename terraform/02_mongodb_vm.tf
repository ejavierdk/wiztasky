resource "azurerm_public_ip" "tf_mongo_public_ip" {
  name                = "tf-mongo-pip"
  location            = azurerm_resource_group.wiz_test_rg.location
  resource_group_name = azurerm_resource_group.wiz_test_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "tf_mongo_nsg" {
  name                = "tf-mongo-nsg"
  location            = azurerm_resource_group.wiz_test_rg.location
  resource_group_name = azurerm_resource_group.wiz_test_rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-MongoDB"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "27017"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "tf_mongo_nic" {
  name                = "tf-mongo-nic"
  location            = azurerm_resource_group.wiz_test_rg.location
  resource_group_name = azurerm_resource_group.wiz_test_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.default.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tf_mongo_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "tf_mongo_nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.tf_mongo_nic.id
  network_security_group_id = azurerm_network_security_group.tf_mongo_nsg.id
}

resource "azurerm_linux_virtual_machine" "tf_mongo_vm" {
  name                = "tf-mongo-vm"
  resource_group_name = azurerm_resource_group.wiz_test_rg.name
  location            = azurerm_resource_group.wiz_test_rg.location
  size                = "Standard_DS2_v2"
  admin_username      = "wizuser"

  network_interface_ids = [
    azurerm_network_interface.tf_mongo_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = "wizuser"
    public_key = file("C:/Users/javier.NORTHAMERICA/.ssh/id_rsa.pub")
  }

  custom_data = base64encode(<<-EOT
    #!/bin/bash
    set -x
    exec > /var/log/custom-data.log 2>&1

    apt-get update
    apt-get install -y gnupg curl
    wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list
    apt-get update
    apt-get install -y mongodb-org
    sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf
    systemctl enable mongod
    systemctl restart mongod

    until mongo --eval "print(\"waited for connection\")"
    do
      sleep 5
    done

    mongo admin --eval 'db.createUser({user:"admin", pwd:"Sk0le0st", roles:[{role:"root", db:"admin"}]})'
    mongo admin --eval 'db.createUser({user:"wizuser", pwd:"Sk0le0st", roles:[{role:"readWriteAnyDatabase", db:"admin"}]})'

  EOT
  )
}

resource "azurerm_role_assignment" "tf_mongo_vm_owner" {
  scope                = azurerm_resource_group.wiz_test_rg.id
  role_definition_name = "Owner"
  principal_id         = azurerm_linux_virtual_machine.tf_mongo_vm.identity[0].principal_id

  depends_on = [
    azurerm_linux_virtual_machine.tf_mongo_vm
  ]
}
