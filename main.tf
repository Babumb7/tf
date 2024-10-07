# main.tf

module "iam" {
  source = "./modules/iam"

  project_name                  = "pw"
  env                           = var.env
  eks_oidc_provider_arn         = module.eks.oidc_provider_arn
  eks_oidc_provider_url         = module.eks.oidc_provider_url
  
}

module "security_groups" {
  source = "./modules/sg"

  project_name          = "pw"
  env                   = var.env
  master_ingress_rules  = var.master_ingress_rules
  master_egress_rules   = var.master_egress_rules
  # workers_ingress_rules = var.workers_ingress_rules
  # workers_egress_rules  = var.workers_egress_rules
}

module "eks" {
  source = "./modules/eks"

  project_name                  = "pw"
  env                           = var.env
  eks_version                   = var.eks_version
  master_role_arn               = module.iam.master_role_arn
  worker_role_arn               = module.iam.worker_role_arn
  desired_size                  = var.desired_size
  max_size                      = var.max_size
  min_size                      = var.min_size
  disk_size                     = var.disk_size
  max_unavailable               = var.max_unavailable
  instance_type                 = var.instance_type
  eks_master_sg_id              = module.security_groups.eks_master_sg_id
  aws_region                    = var.aws_region
  opensearch_instance_count     = var.opensearch_instance_count
  customer_namespace_name       = module.alb_controller.customer_namespace_name
  # internal_namespace_name       = module.alb_controller.internal_namespace_name
  #eks_workers_sg_id           = module.security_groups.eks_workers_sg_id  # Uncomment if needed
}


module "alb_controller" {
  source = "./modules/alb_controller"
  
  project_name            = "pw"
  env                     = var.env
  cluster_name            = module.eks.cluster_name
  cluster_endpoint        = module.eks.cluster_endpoint
  cluster_ca_certificate  = module.eks.cluster_ca_certificate
  oidc_provider_arn       = module.eks.oidc_provider_arn
  aws_region              = var.aws_region
  alb_controller_role_arn = module.iam.alb_controller_role_arn
  eks_alb_sg_id           = module.security_groups.eks_alb_ingress_sg_id

}
