provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "trfGroup" {
  name     = "trf-group"
  location = "Sweden Central"

  tags = {
    environment = "Terraform Test"
  }
}

resource "azurerm_kubernetes_cluster" "trfAKS" {
  name                = "trf-aks"
  location            = azurerm_resource_group.trfGroup.location
  resource_group_name = azurerm_resource_group.trfGroup.name
  dns_prefix          = "trf-k8s"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "Terraform Test"
  }
}