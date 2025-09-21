variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "k8s-cluster"
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc1"
}

variable "node_count" {
  description = "Number of nodes in the cluster"
  type        = number
  default     = 2
}

variable "node_size" {
  description = "Size of the nodes"
  type        = string
  default     = "s-2vcpu-2gb"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "development"
}

variable "create_load_balancer" {
  description = "Whether to create a load balancer"
  type        = bool
  default     = false
}