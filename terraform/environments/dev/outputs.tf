output "aws_cluster_name" { value = try(module.aws[0].cluster_name, null) }
output "gcp_cluster_name" { value = try(module.gcp[0].cluster_name, null) }
output "azure_cluster_name" { value = try(module.azure[0].cluster_name, null) }