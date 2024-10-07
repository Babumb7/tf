#Step 1: Creating a namespace for appmesh
resource "kubernetes_namespace" "appmesh_system" {
  metadata {
    name = "appmesh-system"
  }
}

#Step 2: Installing app mesh controller on k8s cluster
resource "helm_release" "appmesh_controller" {
  name             = "appmesh-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "appmesh-controller"
  namespace        = kubernetes_namespace.appmesh_system.metadata[0].name
  version          = "1.12.3"
  create_namespace = true

  set {
    name  = "region"
    value = "us-east-1"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "appmesh-controller"
  }

  # Uncomment and adjust if needed
  # set {
  #   name  = "nodeSelector.eks.amazonaws.com/nodegroup"
  #   value = "appmesh"
  # }
}

# Step 3: Define App Mesh Components

# 1. Define the Mesh
resource "aws_appmesh_mesh" "mesh" {
  name = "mesh"
  
  tags = {
    Name    = "${var.project_name}-app_mesh-${var.env}"
    Track   = "devops"
    Project = var.project_name
    Env     = var.env
  }
}

# 2. Define the Virtual Node
resource "aws_appmesh_virtual_node" "service_a" {
  name      = "service-a-node"
  mesh_name = aws_appmesh_mesh.mesh.name

  spec {
    listener {
      port_mapping {
        port     = 8080
        protocol = "http"
      }
    }

    service_discovery {
      dns {
        hostname = "service-a.default.svc.cluster.local"  # Kubernetes service discovery hostname
      }
    }
  }
  
  tags = {
    Name    = "${var.project_name}-app_mesh_virtual_nodes-${var.env}"
    Track   = "devops"
    Project = var.project_name
    Env     = var.env
  }
}

# 3. Define the Virtual Service
resource "aws_appmesh_virtual_service" "service_a" {
  name      = "service-a.default.svc.cluster.local"  # Kubernetes service discovery hostname
  mesh_name = aws_appmesh_mesh.mesh.name

  spec {
    provider {
      virtual_node {
        virtual_node_name = aws_appmesh_virtual_node.service_a.name
      }
    }
  }
}

# 4. Define the Virtual Router
resource "aws_appmesh_virtual_router" "service_a" {
  name      = "service-a-router"
  mesh_name = aws_appmesh_mesh.mesh.name

  spec {
    listener {
      port_mapping {
        port     = 8080
        protocol = "http"
      }
    }
  }
}

# 5. Define the Route
resource "aws_appmesh_route" "service_a" {
  name                = "service-a-route"
  mesh_name           = aws_appmesh_mesh.mesh.name
  virtual_router_name = aws_appmesh_virtual_router.service_a.name

  spec {
    http_route {
      match {
        prefix = "/"
      }
      action {
        weighted_target {
          virtual_node = aws_appmesh_virtual_node.service_a.name
          weight       = 1
        }
      }
    }
  }
}

# 6. Define the Virtual Gateway
# resource "aws_appmesh_virtual_gateway" "gateway" {
#   name      = "service-a-gateway"
#   mesh_name = aws_appmesh_mesh.mesh.name

#   spec {
#     listener {
#       port_mapping {
#         port     = 8080
#         protocol = "http"
#       }
#     }
#     backend_defaults {
#       client_policy {
#         tls {
#           enforce = false
#         }
#       }
#     }
#   }

#   tags = {
#     Name    = "app-mesh-virtual-gateway"
#     Track   = "devops"
#     Project = var.project_name
#     Env     = var.env
#   }
# }

# 7. Define the Virtual Gateway Route
# resource "aws_appmesh_virtual_gateway_route" "gateway_route" {
#   name                 = "gateway-route"
#   mesh_name            = aws_appmesh_mesh.mesh.name
#   virtual_gateway_name = aws_appmesh_virtual_gateway.gateway.name

#   spec {
#     http_route {
#       match {
#         prefix = "/"
#       }
#       action {
#         weighted_target {
#           virtual_node = aws_appmesh_virtual_node.service_a.name
#           weight       = 1
#         }
#       }
#     }
#   }
# }

# Step 4: Define Kubernetes Resources

# 1. Kubernetes Deployment for the Service(to test)
resource "kubernetes_deployment" "service_a" {
  metadata {
    name      = "service-a"
    namespace = "appmesh-system"
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "service-a"
      }
    }

    template {
      metadata {
        labels = {
          app = "service-a"
        }
        annotations = {
          "appmesh.k8s.aws/mesh"          = aws_appmesh_mesh.mesh.name
          "appmesh.k8s.aws/virtualNode"   = aws_appmesh_virtual_node.service_a.name
        }
      }

      spec {
        container {
          name  = "app"
          image = "nginx"

          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

# 2. Kubernetes Service to Expose the Deployment (Testing purpose)
resource "kubernetes_service" "service_a" {
  metadata {
    name      = "service-a"
    namespace = "appmesh-system"
  }

  spec {
    selector = {
      app = "service-a"
    }

    port {
      port        = 8080
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

# 3. Kubernetes Service for the Virtual Gateway
resource "kubernetes_service" "gateway" {
  metadata {
    name      = "service-a-gateway"
    namespace = "appmesh-system"
  }

  spec {
    selector = {
      app = "service-a"
    }

    port {
      port        = 8080
      target_port = 8080
    }

    type = "ClusterIP"
  }
}
