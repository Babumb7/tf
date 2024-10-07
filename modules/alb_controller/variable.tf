variable "cluster_name" {}
variable "cluster_endpoint" {}
variable "cluster_ca_certificate" {}
variable "oidc_provider_arn" {}
variable "aws_region" {}
variable "alb_controller_role_arn" {}
variable "env" {}
variable "eks_alb_sg_id" {}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

