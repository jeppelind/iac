variable "host" {
  type        = string
  description = "Cluster server (clusters.cluster.server)"
}

variable "client_certificate" {
  type        = string
  description = "Client certificate (users.user.client-certificate)"
}

variable "client_key" {
  type        = string
  description = "Client key (users.user.client-key)"
}

variable "cluster_ca_certificate" {
  description = "Cluster certificate (clusters.cluster.certificate-authority-data)"
}
