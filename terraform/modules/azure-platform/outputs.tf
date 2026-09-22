output "cluster_name" { value = azurerm_kubernetes_cluster.platform.name }
output "cluster_fqdn" { value = azurerm_kubernetes_cluster.platform.fqdn }
output "resource_group_name" { value = azurerm_resource_group.platform.name }
output "workload_identity_id" { value = azurerm_user_assigned_identity.workload.id }