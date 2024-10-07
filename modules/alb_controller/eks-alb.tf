################################################################################################

# Data sources for existing VPC components
data "aws_vpc" "pw_vpc" {
  filter {
    name   = "tag:Name"
    values = ["pw-vpc-${var.env}"]
  }
}

data "aws_eks_cluster_auth" "pw_eks" {
  name = var.cluster_name
}

data "aws_subnet" "private_subnet_az1" {
  filter {
    name   = "tag:Name"
    values = ["pw-public-subnet-az1-${var.env}"]
  }
}

data "aws_subnet" "private_subnet_az2" {
  filter {
    name   = "tag:Name"
    values = ["pw-public-subnet-az2-${var.env}"]
  }
}

###########################################################################################


# provider "kubernetes" {
#   host                   = var.cluster_endpoint
#   cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = var.cluster_endpoint
#     cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
#     }
#   }
# }



provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.pw_eks.token
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.pw_eks.token
  }
}




resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = var.alb_controller_role_arn
    }
  }
}


# resource "null_resource" "verify_kubernetes_connection" {
#   provisioner "local-exec" {
#     command = <<-EOT
#       echo "Current AWS Account ID: $(aws sts get-caller-identity --query Account --output text)"
#       aws eks describe-cluster --name ${var.cluster_name} --region ${var.aws_region}
#       aws eks get-token --cluster-name ${var.cluster_name} > /dev/null
#       if [ $? -eq 0 ]; then
#         echo "Successfully authenticated with EKS cluster"
#         aws eks list-nodegroups --cluster-name ${var.cluster_name}
#         if [ $? -eq 0 ]; then
#           echo "Successfully listed nodegroups in the EKS cluster"
#         else
#           echo "Failed to list nodegroups in the EKS cluster"
#           exit 1
#         fi
#       else
#         echo "Failed to authenticate with EKS cluster"
#         exit 1
#       fi
#     EOT
#   }
# }

# resource "null_resource" "debug_info" {
#   provisioner "local-exec" {
#     command = <<-EOT
#       echo "Current AWS Account ID: $(aws sts get-caller-identity --query Account --output text)"
#       echo "Cluster Name: ${var.cluster_name}"
#       echo "Region: ${var.aws_region}"
#       aws eks list-clusters --region ${var.aws_region}
#     EOT
#   }
# }

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.4.4"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.alb_controller_role_arn
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = data.aws_vpc.pw_vpc.id
  }

    # depends_on = [null_resource.verify_kubernetes_connection]


  # depends_on = [kubernetes_service_account.aws_load_balancer_controller]
}

# ################################ internal ingress resources  ####################################

resource "kubernetes_namespace" "internal" {
  metadata {
    name = "internal"
  }
}

resource "kubernetes_ingress_v1" "internal" {
  metadata {
    name      = "alb-ingress-internal"
    namespace = kubernetes_namespace.internal.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                   = "alb"
      "alb.ingress.kubernetes.io/scheme"              = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"         = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path"    = "/"
      "alb.ingress.kubernetes.io/subnets"             = "subnet-001b007376e1d0dce,subnet-09c8e3fa99b8e7fa0"
      "alb.ingress.kubernetes.io/load-balancer-name"  = "${var.project_name}-alb-internal-${var.env}"
    }
  }
  spec {
    ingress_class_name = "alb"  # Replace with your ingress class

    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "vehicle"
              port {
                number = 9090
              }
            }
          }
        }

        path {
          path      = "/api"
          path_type = "Prefix"
          backend {
            service {
              name = "geolocation"
              port {
                number = 9090
              }
            }
          }
        }

        # path {
        #   path      = "/api/product/health"
        #   path_type = "Prefix"
        #   backend {
        #     service {
        #       name = "product"
        #       port {
        #         number = 8080
        #       }
        #     }
        #   }
        # }

        # path {
        #   path      = "/api/user"
        #   path_type = "Prefix"
        #   backend {
        #     service {
        #       name = "user"
        #       port {
        #         number = 8080
        #       }
        #     }
        #   }
        # }

        # # path {
        # #   path      = "/vehicleTracking"
        # #   path_type = "Prefix"
        # #   backend {
        # #     service {
        # #       name = "vehicle1"
        # #       port {
        # #         number = 9090
        # #       }
        # #     }
        # #   }
        # # }
        # path {
        #   path      = "/vehicleTracking"
        #   path_type = "Prefix"
        #   backend {
        #     service {
        #       name = "vehicle1"
        #       port {
        #         number = 9090
        #       }
        #     }
        #   }
        # }

        # path {
        #   path      = "/storage"
        #   path_type = "Prefix"
        #   backend {
        #     service {
        #       name = "storage"
        #       port {
        #         number = 8092
        #       }
        #     }
        #   }
        # }

        # # path {
        # #   path      = "/app1"
        # #   path_type = "Prefix"
        # #   backend {
        # #     service {
        # #       name = "nginx-service1"
        # #       port {
        # #         number = 80
        # #       }
        # #     }
        # #   }
        # # }

        # path {
        #   path      = "/pulseapi"
        #   path_type = "Prefix"
        #   backend {
        #     service {
        #       name = "pulse"
        #       port {
        #         number = 4000
        #       }
        #     }
        #   }
        # }


      }
    }
  }
}