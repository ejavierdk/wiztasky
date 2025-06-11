/*
05_aks.tf

Deploys a managed Azure Kubernetes Service (AKS) cluster in the existing network and grants permissive cluster-admin RBAC permissions.
Assumptions:
- Resource group `tf-wiz-test-rg` exists
- Virtual network `tf-mongo-vnet` with subnet `default` exists
*/

// Reference existing resource group
data "azurerm_resource_group" "rg" {
  name = "tf-wiz-test-rg"
}

// Reference existing virtual network
data "azurerm_virtual_network" "vnet" {
  name                = "tf-mongo-vnet"
  resource_group_name = data.azurerm_resource_group.rg.name
}

// Reference existing subnet
data "azurerm_subnet" "aks_subnet" {
  name                 = "default"
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

// AKS cluster creation
data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "tf-wiz-aks"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  dns_prefix = "tfwizaks"

  default_node_pool {
    name           = "agentpool"
    node_count     = 2
    vm_size        = "Standard_DS2_v2"
    vnet_subnet_id = data.azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    service_cidr      = "10.0.10.0/24"
    dns_service_ip    = "10.0.10.10"
    
  }

  tags = {
    Environment = "wizexercise"
  }
}

// Write kubeconfig locally
resource "local_file" "kubeconfig" {
  content  = azurerm_kubernetes_cluster.aks.kube_config_raw
  filename = "./kubeconfig"
}

// Kubernetes provider configuration
data "azurerm_kubernetes_cluster" "cluster" {
  name                = azurerm_kubernetes_cluster.aks.name
  resource_group_name = azurerm_kubernetes_cluster.aks.resource_group_name
}

provider "kubernetes" {
  config_path = "./kubeconfig"
}


// Permissive RBAC binding
resource "kubernetes_cluster_role_binding" "permissive" {
  metadata {
    name = "permissive-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "Group"
    name      = "system:authenticated"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "Group"
    name      = "system:unauthenticated"
    api_group = "rbac.authorization.k8s.io"
  }
}
