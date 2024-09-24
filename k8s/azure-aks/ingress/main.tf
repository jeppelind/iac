// ------------------------
// Using ingress to expose deployment
// ------------------------

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
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "nginx" {
  provider = kubernetes.aks

  wait_for_load_balancer = true
  metadata {
    name = "nginx-ingress"
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        path {
          path = "/*"
          backend {
            service {
              name = kubernetes_service.nginx.metadata.0.name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
