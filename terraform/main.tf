provider "digitalocean" {
  token = var.do_token
}

# Get available Kubernetes versions
data "digitalocean_kubernetes_versions" "k8s_versions" {}

# Create the Kubernetes cluster
resource "digitalocean_kubernetes_cluster" "k8s" {
  name    = var.cluster_name
  region  = var.region
  version = data.digitalocean_kubernetes_versions.k8s_versions.valid_versions[0]

  node_pool {
    name       = "worker-pool"
    size       = var.node_size
    node_count = var.node_count
  }

  tags = ["kubernetes", "terraform", var.environment]
}

# Create a VPC for the cluster
resource "digitalocean_vpc" "k8s_vpc" {
  name     = "${var.cluster_name}-vpc"
  region   = var.region
  ip_range = "10.10.0.0/16"
}

# Optional: Create a load balancer
resource "digitalocean_loadbalancer" "k8s_lb" {
  count  = var.create_load_balancer ? 1 : 0
  name   = "${var.cluster_name}-lb"
  region = var.region
  
  forwarding_rule {
    entry_protocol  = "http"
    entry_port      = 80
    target_protocol = "http"
    target_port     = 80
  }
  
  forwarding_rule {
    entry_protocol  = "https"
    entry_port      = 443
    target_protocol = "https"
    target_port     = 443
    tls_passthrough = true
  }
  
  healthcheck {
    protocol = "http"
    port     = 80
    path     = "/"
  }
  
  depends_on = [digitalocean_kubernetes_cluster.k8s]
}