# use a second state inside of the cluster. This will create the secret automatically.
terraform {
  backend "kubernetes" {
    in_cluster_config = true
    secret_suffix = "incluster"
  }
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.0.3"
    }
  }
}

# in_cluster_config is automatically detected
provider "kubernetes" {}

resource "kubernetes_pod" "test" {
  metadata {
    name = "managed-by-tf-in-cluster"
  }
  spec {
    container {
      #image = "docker.io/library/busybox:1.32.0"
      image = "localhost:5000/busybox:1.32.0"
      name  = "containername"
      command = ["sleep", "300s"]
    }
  }
}
