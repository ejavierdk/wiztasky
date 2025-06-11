/*
04_backup.tf

Installs the backup script on the MongoDB VM & grants data-plane rights; cron job will be managed manually on the VM.
Assumptions:
- Azure CLI installed on VM via 02_mongodb_vm.tf Custom Script Extension
- VM has system-assigned identity with Owner role
- `backup_mongo_to_blob.sh` present in this module directory
*/

locals {
  resource_group_name    = "tf-wiz-test-rg"
  mongo_vm_name          = "tf-mongo-vm"
  public_ip_name         = "tf-mongo-pip"
  backup_script_path     = "${path.module}/backup_mongo_to_blob.sh"
  backup_destination_dir = "/opt/mongo-backup"
  temp_script_path       = "/home/wizuser/backup_mongo_to_blob.sh"
}

// Fetch VM public IP
data "azurerm_public_ip" "mongo_vm_ip" {
  name                = local.public_ip_name
  resource_group_name = local.resource_group_name
}

// Deploy backup script via SSH
resource "null_resource" "install_backup_script" {
  depends_on = [ data.azurerm_public_ip.mongo_vm_ip ]

  triggers = {
    script_sha = filesha256(local.backup_script_path)
  }

  connection {
    type  = "ssh"
    host  = data.azurerm_public_ip.mongo_vm_ip.ip_address
    user  = "wizuser"
    agent = true
  }

  provisioner "file" {
    source      = local.backup_script_path
    destination = local.temp_script_path
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p ${local.backup_destination_dir}",
      "sudo mv ${local.temp_script_path} ${local.backup_destination_dir}/backup_mongo_to_blob.sh",
      "sudo chmod +x ${local.backup_destination_dir}/backup_mongo_to_blob.sh"
    ]
  }
}

// Grant data-plane access to the storage account
data "azurerm_storage_account" "backup_sa" {
  name                = "tfwizstoragejavierlab"
  resource_group_name = local.resource_group_name
}

data "azurerm_virtual_machine" "mongo_vm_data" {
  name                = local.mongo_vm_name
  resource_group_name = local.resource_group_name
}

resource "azurerm_role_assignment" "vm_blob_data_contrib" {
  scope                = data.azurerm_storage_account.backup_sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_virtual_machine.mongo_vm_data.identity[0].principal_id
}
