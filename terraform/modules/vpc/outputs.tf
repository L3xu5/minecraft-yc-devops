output "network_id" {
  value = yandex_vpc_network.main.id
}

output "subnet_id" {
  value = yandex_vpc_subnet.main.id
}

output "subnet_zone" {
  value = yandex_vpc_subnet.main.zone
}

output "main_security_group_id" {
  value = yandex_vpc_security_group.k8s_main.id
}

output "public_security_group_id" {
  value = yandex_vpc_security_group.k8s_public.id
}
