resource "azurerm_virtual_machine_extension" "tf_mongo_backup_script" {
  name                 = "tf-mongo-backup-script"
  virtual_machine_id   = azurerm_linux_virtual_machine.tf_mongo_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
    {
      "fileUris": ["https://raw.githubusercontent.com/ejavierdk/wiztasky/main/backup_mongo_to_blob.sh"],
      "commandToExecute": "chmod +x backup_mongo_to_blob.sh && mv backup_mongo_to_blob.sh /home/wizuser/backup_mongo_to_blob.sh"
    }
  SETTINGS
}

resource "azurerm_virtual_machine_extension" "tf_mongo_backup_cron" {
  name                 = "tf-mongo-backup-cron"
  virtual_machine_id   = azurerm_linux_virtual_machine.tf_mongo_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
    {
      "commandToExecute": "(crontab -u wizuser -l 2>/dev/null; echo '0 */12 * * * /home/wizuser/backup_mongo_to_blob.sh') | crontab -u wizuser -"
    }
  SETTINGS
}
