resource "yandex_iam_service_account" "k8s" {
  name        = var.service_account_name
  description = "Service account for Minecraft Kubernetes cluster"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_images_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

resource "yandex_kubernetes_cluster" "main" {
  name        = var.cluster_name
  description = "Managed Kubernetes for Minecraft server"
  network_id  = var.network_id

  cluster_ipv4_range = var.master_cidr
  service_ipv4_range = var.node_cidr

  master {
    version = var.k8s_version

    master_location {
      zone      = var.subnet_zone
      subnet_id = var.subnet_id
    }

    public_ip = true

    security_group_ids = [var.main_security_group_id]
  }

  service_account_id      = yandex_iam_service_account.k8s.id
  node_service_account_id = yandex_iam_service_account.k8s.id

  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_editor,
    yandex_resourcemanager_folder_iam_member.k8s_images_puller,
  ]
}

resource "yandex_kubernetes_node_group" "main" {
  name        = var.node_group_name
  description = "Nodes for Minecraft workload"
  cluster_id  = yandex_kubernetes_cluster.main.id
  version     = var.k8s_version

  scale_policy {
    auto_scale {
      min     = var.enable_autoscaling ? var.node_count_min : var.node_count
      max     = var.enable_autoscaling ? var.node_count_max : var.node_count
      initial = var.node_count
    }
  }

  allocation_policy {
    location {
      zone = var.subnet_zone
    }
  }

  deploy_policy {
    max_expansion   = 1
    max_unavailable = 0
  }

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      nat                = false
      subnet_ids         = [var.subnet_id]
      security_group_ids = [var.main_security_group_id, var.public_security_group_id]
    }

    resources {
      cores  = var.node_cores
      memory = var.node_memory_gb
    }

    boot_disk {
      type = var.node_disk_type
      size = var.node_disk_gb
    }

    metadata = {
      enable-oslogin = "true"
    }

    scheduling_policy {
      preemptible = var.node_preemptible
    }
  }
}
