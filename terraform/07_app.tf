/*
07_app.tf

Deploys the Tasky web application to the AKS cluster.
Assumptions:
- AKS cluster has ACR integration enabled via az aks update --attach-acr.
- AzureRM and Kubernetes providers are configured to use the generated kubeconfig.
- ACR image "tasky:latest" exists in azurerm_container_registry.acr.
- MongoDB VM private IP is accessible via VNet.
*/

// Fetch the MongoDB VM private IP
data "azurerm_network_interface" "mongo_nic" {
  name                = "tf-mongo-nic"
  resource_group_name = azurerm_resource_group.wiz_test_rg.name
}

// Fetch ACR login server for image reference
data "azurerm_container_registry" "acr_data" {
  name                = azurerm_container_registry.acr.name
  resource_group_name = azurerm_resource_group.wiz_test_rg.name
}

// Kubernetes Deployment for Tasky
resource "kubernetes_deployment" "tasky" {
  metadata {
    name      = "tasky"
    namespace = "default"
    labels    = { app = "tasky" }
  }

  spec {
    replicas                = 2
    progress_deadline_seconds = 600

    selector {
      match_labels = { app = "tasky" }
    }

    template {
      metadata {
        labels = { app = "tasky" }
      }

      spec {
        // No pull secrets needed with AKS-ACR integration
        container {
          name  = "tasky"
          image = "${data.azurerm_container_registry.acr_data.login_server}/tasky:latest"

          // Ensure the app binds on all interfaces and correct port
          env {
            name  = "HOST"
            value = "0.0.0.0"
          }
          env {
            name  = "PORT"
            value = "8080"
          }

          // Expose the correct container port
          port {
            container_port = 8080
          }

          env {
            name  = "MONGODB_URI"
            value = "mongodb://admin:Sk0le0st@${data.azurerm_network_interface.mongo_nic.ip_configuration[0].private_ip_address}:27017/admin"
          }
          env {
            name  = "SECRET_KEY"
            value = "ReplaceWithYourSecret"
          }
        }
      }
    }
  }
}

// Expose Tasky via LoadBalancer
resource "kubernetes_service" "tasky_lb" {
  metadata {
    name      = "tasky"
    namespace = "default"
    labels    = { app = "tasky" }
  }

  spec {
    selector = { app = "tasky" }
    port {
      port        = 80
      target_port = 8080
    }
    type = "LoadBalancer"
  }
}

// Output the external IP
output "tasky_lb_ip" {
  description = "External IP of the Tasky LoadBalancer"
  value       = kubernetes_service.tasky_lb.status[0].load_balancer[0].ingress[0].ip
}
