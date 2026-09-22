output "cluster_name" { value = module.cluster.cluster_name }
output "cluster_endpoint" { value = module.cluster.cluster_endpoint }
output "vpc_id" { value = module.network.vpc_id }
output "workload_role_arn" { value = aws_iam_role.workload.arn }
output "vm_id" { value = try(aws_instance.portfolio_vm[0].id, null) }