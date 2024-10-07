# Outputs
output "master_role_arn" {
  value = aws_iam_role.master.arn
}

output "worker_role_name" {
  description = "Name of the EKS worker IAM role"
  value       = aws_iam_role.worker.name
}


output "worker_role_arn" {
  value = aws_iam_role.worker.arn
}

output "worker_instance_profile_name" {
  value = aws_iam_instance_profile.worker.name
}

output "alb_controller_role_arn" {
  value = aws_iam_role.aws_load_balancer_controller.arn
}



# output "fargate_pod_execution_role_arn" {
#   value = aws_iam_role.fargate_pod_execution_role.arn
# }