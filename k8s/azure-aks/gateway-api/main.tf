// ------------------------
// Using Gateway API
// With nginx gateway fabric https://docs.nginx.com/nginx-gateway-fabric/
// Note: nginx-gateway-fabric needs to be installed in cluster before applying this config
// ------------------------

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
  required_version = ">= 1.1.0"
}

data "terraform_remote_state" "aks" {
  backend = "local"
  config = {
    path = "../../../azure-aks-terraform/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_kubernetes_cluster" "cluster" {
  name                = data.terraform_remote_state.aks.outputs.kubernetes_cluster_name
  resource_group_name = data.terraform_remote_state.aks.outputs.resource_group_name
}

provider "kubernetes" {
  alias                  = "aks"
  host                   = data.azurerm_kubernetes_cluster.cluster.kube_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate)
}

provider "kubectl" {
  host                   = data.azurerm_kubernetes_cluster.cluster.kube_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate)
  load_config_file       = false
}

resource "kubernetes_deployment" "nginx" {
  provider = kubernetes.aks

  metadata {
    name = "nginx-test"
    labels = {
      app = "nginx-scalable-test"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "nginx-scalable-test"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx-scalable-test"
        }
      }
      spec {
        container {
          name  = "test"
          image = "nginx:1.27.1"
          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "nginx" {
  provider = kubernetes.aks

  metadata {
    name = "nginx-test-service"
  }

  spec {
    selector = {
      app = kubernetes_deployment.nginx.spec.0.template.0.metadata[0].labels.app
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
      protocol = "TCP"
    }
  }
}

resource "kubectl_manifest" "gateway" {
    yaml_body = <<YAML
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gateway
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
YAML
}

resource "kubectl_manifest" "httproute" {
    yaml_body = <<YAML
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httproute
spec:
  parentRefs:
  - name: gateway
  hostnames:
  - "dummy.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: nginx-test-service
      port: 80
YAML
}

# resource "kubernetes_manifest" "gateway" {
#   manifest = {
#     "apiVersion" = "gateway.networking.k8s.io/v1"
#     "kind" = "Gateway"
#     "metadata" = {
#       "name" = "gateway"
#     }
#     "spec" = {
#       "gatewayClassName" = "nginx"
#       "listeners" = [
#         {
#           "name" = "http"
#           "port" = 80
#           "protocol" = "HTTP"
#         },
#       ]
#     }
#   }
# }

# resource "kubernetes_manifest" "httproute" {
#   manifest = {
#     "apiVersion" = "gateway.networking.k8s.io/v1"
#     "kind" = "HTTPRoute"
#     "metadata" = {
#       "name" = "httproute"
#     }
#     "spec" = {
#       "parentRefs" = [
#         {
#           "name": "gateway"
#         },
#       ]
#       "hostnames" = [
#         "cafe.example.com",
#       ]
#       "rules" = [
#         {
#           "matches" = [
#             {
#               "path" = {
#                 "type" = "PathPrefix"
#                 "value" = "/"
#               }
#             },
#           ]
#           "backendRefs" = [
#             {
#               "name" = "nginx-test-service"
#               "port" = 80
#             },
#           ]
#         }
#       ]
#     }
#   }
# }
