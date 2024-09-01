output "resource_group_name" {
  value = azurerm_resource_group.trfGroup.name
}

output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.trfAKS.name
}