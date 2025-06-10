resource "azurerm_storage_account" "tf_wiz_storage" {
  name                     = "tfwizstoragejavierlab"
  resource_group_name      = azurerm_resource_group.wiz_test_rg.name
  location                 = azurerm_resource_group.wiz_test_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tf_backups" {
  name                 = "tf-backups"
  storage_account_id   = azurerm_storage_account.tf_wiz_storage.id
  container_access_type = "container"
}

