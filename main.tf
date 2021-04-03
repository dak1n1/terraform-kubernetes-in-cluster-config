# This config runs locally, but stores state inside the cluster. It will create the secret automatically.
# When terraform is run, it creates a second secret, used by a second instance of terraform, which runs in a pod.
# That terraform instance mounts the terraform config located in ./in_cluster_config

terraform {
  backend "kubernetes" {
    secret_suffix     = "outside"
    config_path      = "~/.kube/config"
#    config_paths      = [
#      "~/.kube/config",
#      "~/.kube/second"
#    ]
  }
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.0.3"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_pod" "test" {
  depends_on = [kubernetes_role_binding.test]
  metadata {
    name = "terraform-runner"
    labels = {
      app = "TerraformInCluster"
    }
  }
  spec {
    service_account_name = kubernetes_service_account.test.metadata.0.name
    init_container {
      name  = "copy-terraform-config"
      image = "localhost:5000/terraform:dev"
      working_dir = "/workspace"
      command = ["/bin/bash"]
      args = ["-x", "-c", "cp -v /configmap/main.tf ."]
      volume_mount {
        mount_path = "/configmap"
        name = "terraform-config"
      }
      volume_mount {
        mount_path = "/workspace"
        name = "workspace"
      }
    }

    init_container {
      name  = "terraform-init"
      image = "localhost:5000/terraform:dev"
      working_dir = "/workspace"
      command = ["terraform"]
      args = ["init"]
      env {
        name  = "TF_LOG"
        value = "trace"
      }
      volume_mount {
        mount_path = "/workspace"
        name = "workspace"
      }
    }

    container {
      name  = "terraform-apply"
      image = "localhost:5000/terraform:dev"
      working_dir = "/workspace"
      command = ["terraform"]
      args = ["apply --auto-approve"]
      env {
        name  = "TF_LOG"
        value = "trace"
      }
      volume_mount {
        mount_path = "/workspace"
        name = "workspace"
      }
    }
    volume {
      name = "terraform-config"
      config_map {
        name = kubernetes_config_map.test.metadata.0.name
      }
    }
    volume {
      name = "workspace"
      empty_dir {
        size_limit = "1G"
      }
    }
  }
}

resource "kubernetes_config_map" "test" {
  metadata {
    name = "test"
    labels = {
      app = "TerraformInCluster"
    }
  }
  data = {
    "main.tf"      = file("${path.module}/in_cluster_config/main.tf")
  }
}

resource "kubernetes_service_account" "test" {
  metadata {
    name = "terraform-runner"
    labels = {
      app = "TerraformInCluster"
    }
  }
}

resource "kubernetes_role" "test" {
  metadata {
    name = "terraform-in-cluster"
    labels = {
      app = "TerraformInCluster"
    }
  }

  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    verbs          = ["get", "list", "watch", "create"]
  }

  rule {
    api_groups     = ["coordination.k8s.io"]
    resources      = ["leases"]
    verbs          = ["get", "list", "watch", "create", "delete"]
  }
}

resource "kubernetes_role_binding" "test" {
  metadata {
    name      = "terraform-in-cluster"
    namespace = "default"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.test.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.test.metadata.0.name
    namespace = "default"
  }
}
