
provider "kubernetes" {
  host                   = var.host
  client_certificate     = base64decode(var.client_certificate)
  client_key             = base64decode(var.client_key)
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
}

resource "kubernetes_deployment" "nginx" {
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

resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx-test-service"
  }

  spec {
    selector = {
      app = kubernetes_deployment.nginx.spec.0.template.0.metadata[0].labels.app
    }
    port {
      name = "http"
      port = 80
      target_port = 80
      node_port = 30444 // Not relevant when running minikube tunnel as it assigns random port
    }

    type = "NodePort"
  }
}