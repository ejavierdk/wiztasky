/*
06_acr.tf

Creates an Azure Container Registry and grants your AKS cluster pull permissions.
Assumptions:
- The resource group `azurerm_resource_group.wiz_test_rg` is defined elsewhere.
- The client config `data.azurerm_client_config.current` and AKS resource `azurerm_kubernetes_cluster.aks` exist.
*/

resource "azurerm_container_registry" "acr" {
  name                = "tfwizacr${substr(data.azurerm_client_config.current.subscription_id, 0, 6)}"
  resource_group_name = azurerm_resource_group.wiz_test_rg.name
  location            = azurerm_resource_group.wiz_test_rg.location
  sku                 = "Standard"
  admin_enabled       = true   // enable admin user so admin_password is available

  tags = {
    Environment = "wizexercise"
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

// Short ACR name for CLI login (no .azurecr.io suffix)
output "acr_name" {
  description = "The short registry name for az acr login commands"
  value       = azurerm_container_registry.acr.name
}
