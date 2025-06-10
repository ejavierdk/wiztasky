provider "azurerm" {
  features {}

  subscription_id = "17a02a84-4ade-4b31-9a8e-91997f0c1457"

}

resource "azurerm_resource_group" "wiz_test_rg" {
  name     = "tf-wiz-test-rg"
  location = "eastus"
}

resource "azurerm_virtual_network" "mongo_vnet" {
  name                = "tf-mongo-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.wiz_test_rg.location
  resource_group_name = azurerm_resource_group.wiz_test_rg.name
}

resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.wiz_test_rg.name
  virtual_network_name = azurerm_virtual_network.mongo_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}
