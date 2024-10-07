
# Data sources for existing VPC components
data "aws_vpc" "existing_vpc" {
  filter {
    name   = "tag:Name"
    values = ["pw-vpc-${var.env}"]
  }
}

data "aws_subnet" "private_subnet_az1" {
  filter {
    name   = "tag:Name"
    values = ["pw-private-subnet-az1-${var.env}"]
  }
}

data "aws_subnet" "private_subnet_az2" {
  filter {
    name   = "tag:Name"
    values = ["pw-private-subnet-az2-${var.env}"]
  }
}


data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "pw_eks" {
  name = aws_eks_cluster.eks.name
}

data "aws_kms_key" "cloudwatch-log-group" {
  key_id = "alias/accelerator/kms/cloudwatch/key"
}


#####################################################################################################

provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.pw_eks.token
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.pw_eks.token
  }
}

# Creating EKS Cluster
resource "aws_eks_cluster" "eks" {
  name     = "${var.project_name}-eks-cluster-${var.env}"
  role_arn = var.master_role_arn
  version  = var.eks_version

  vpc_config {
    subnet_ids              = [data.aws_subnet.private_subnet_az1.id, data.aws_subnet.private_subnet_az2.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
    security_group_ids      = [var.eks_master_sg_id]
  }

  # Enable all log types
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }


  # Ensure that CloudWatch log group is created before the EKS cluster
  depends_on = [aws_cloudwatch_log_group.eks_cluster]

  tags = {
    Name    = "${var.project_name}-cluster-${var.env}"
    Track   = "devops"
    Project = var.project_name
    Env     = var.env
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# Create CloudWatch Log Group for EKS cluster logs
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.project_name}-cluster-${var.env}/cluster"
  retention_in_days = 7
  
  kms_key_id  = data.aws_kms_key.cloudwatch-log-group.arn

  tags = {
    Name    = "${var.project_name}-eks-cluster-logs-${var.env}"
    Track   = "devops"
    Project = var.project_name
    Env     = var.env
  }
}


#######################################################################
#oidc 

data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}