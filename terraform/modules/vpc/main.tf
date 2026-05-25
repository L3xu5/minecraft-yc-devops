resource "yandex_vpc_network" "main" {
  name        = var.network_name
  description = "VPC for Minecraft Kubernetes cluster"
}

resource "yandex_vpc_subnet" "main" {
  name           = var.subnet_name
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.subnet_cidr]
  description    = "Subnet in ${var.zone}"
}

# Базовая SG кластера (master + nodes)
resource "yandex_vpc_security_group" "k8s_main" {
  name        = "${var.network_name}-main-sg"
  description = "Cluster master and node baseline rules"
  network_id  = yandex_vpc_network.main.id

  ingress {
    description       = "Load balancer health checks"
    protocol          = "TCP"
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    description       = "Intra security group traffic"
    protocol          = "ANY"
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    description    = "ICMP from private networks"
    protocol       = "ICMP"
    v4_cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    description    = "Kubernetes API (kubectl)"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    description    = "Kubernetes API (kubectl)"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 6443
  }

  egress {
    description       = "Egress within security group"
    protocol          = "ANY"
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }
}

# SG для публичных сервисов на node group (NLB, NodePort, Minecraft)
resource "yandex_vpc_security_group" "k8s_public" {
  name        = "${var.network_name}-public-sg"
  description = "Public ingress for LoadBalancer and Minecraft"
  network_id  = yandex_vpc_network.main.id

  ingress {
    description    = "Pod and service traffic inside cluster CIDRs"
    protocol       = "ANY"
    v4_cidr_blocks = [var.master_cidr, var.node_cidr]
    from_port      = 0
    to_port        = 65535
  }

  ingress {
    description    = "NodePort range"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 30000
    to_port        = 32767
  }

  ingress {
    description    = "Minecraft Java Edition"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = var.minecraft_port
  }

  egress {
    description    = "All outbound (Docker Hub, YCR, etc.)"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}
