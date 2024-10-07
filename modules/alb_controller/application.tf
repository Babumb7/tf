resource "kubernetes_namespace" "customer" {
  metadata {
    name = "customer"
  }
}

resource "kubernetes_ingress_v1" "customer" {
  metadata {
    name      = "alb-ingress-customer"
    namespace = kubernetes_namespace.customer.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                   = "alb"
      "alb.ingress.kubernetes.io/scheme"              = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"         = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path"    = "/health"
      "alb.ingress.kubernetes.io/subnets"             = "subnet-001b007376e1d0dce,subnet-09c8e3fa99b8e7fa0"
      "alb.ingress.kubernetes.io/security-groups"     = var.eks_alb_sg_id
      "alb.ingress.kubernetes.io/load-balancer-name"  = "${var.project_name}-alb-customer-${var.env}"

    }
  }
  spec {
    ingress_class_name = "alb"  # Replace with your ingress class

    rule {
      http {
        path {
          path      = "/customer"
          path_type = "Prefix"
          backend {
            service {
              name = "customer-service"
              port {
                number = 8081
              }
            }
          }
        }

        

        

        path {
          path      = "/job"
          path_type = "Prefix"
          backend {
            service {
              name = "job-service"
              port {
                number = 8080
              }
            }
          }
        }


      }
    }
  }
}