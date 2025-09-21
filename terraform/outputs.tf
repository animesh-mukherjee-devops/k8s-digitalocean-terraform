output "cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.k8s.id
}

output "cluster_endpoint" {
  description = "Endpoint of the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.k8s.endpoint
}

output "cluster_status" {
  description = "Status of the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.k8s.status
}

output "cluster_version" {
  description = "Version of the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.k8s.version
}

output "kubeconfig" {
  description = "Kubeconfig for the cluster"
  value       = digitalocean_kubernetes_cluster.k8s.kube_config[0].raw_config
  sensitive   = true
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = digitalocean_vpc.k8s_vpc.id
}

output "load_balancer_ip" {
  description = "IP address of the load balancer"
  value       = var.create_load_balancer ? digitalocean_loadbalancer.k8s_lb[0].ip : null
}