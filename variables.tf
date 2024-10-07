# variables.tf


variable "aws_region" {
  description = "region (e.g., dev, qa, prod)"
  type        = string
}

variable "assume_role_arn" {
  description = "roles for (e.g., dev, qa, prod)"
  type        = string
}

variable "env" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "eks_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
}

variable "disk_size" {
  description = "Size of the EBS volume for each node in GB"
  type        = number
}

variable "max_unavailable" {
  description = "Size of the EBS volume for each node in GB"
  type        = number
}
variable "instance_type" {
  description = "EC2 instance type for the EKS nodes"
  type        = string
}

# variable "eks_ami_id" {
#   description = "AMI ID for the EKS worker nodes"
#   type        = string
# }

variable "master_ingress_rules" {
  description = "List of ingress rules for the EKS master security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
}

variable "master_egress_rules" {
  description = "List of egress rules for the EKS master security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
}

variable "opensearch_instance_count" {
  description = "The instance count for opensearch (e.g., dev, qa, prod)"
  type        = number
}

# variable "workers_ingress_rules" {
#   description = "List of ingress rules for the EKS workers security group"
#   type = list(object({
#     from_port   = number
#     to_port     = number
#     protocol    = string
#     cidr_blocks = list(string)
#     description = string
#   }))
# }

# variable "workers_egress_rules" {
#   description = "List of egress rules for the EKS workers security group"
#   type = list(object({
#     from_port   = number
#     to_port     = number
#     protocol    = string
#     cidr_blocks = list(string)
#     description = string
#   }))
# }