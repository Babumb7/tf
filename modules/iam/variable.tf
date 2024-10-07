variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "env" {
  description = "Environment (e.g., dev, staging, prod)"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC Provider"
  type        = string
}

variable "eks_oidc_provider_url" {
  description = "URL of the EKS OIDC Provider"
  type        = string
}


