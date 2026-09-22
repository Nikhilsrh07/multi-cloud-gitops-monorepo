output "cluster_name" { value = google_container_cluster.platform.name }
output "cluster_endpoint" { value = google_container_cluster.platform.endpoint }
output "network_name" { value = google_compute_network.platform.name }
output "workload_service_account" { value = google_service_account.workload.email }
output "vm_id" { value = try(google_compute_instance.portfolio_vm[0].id, null) }