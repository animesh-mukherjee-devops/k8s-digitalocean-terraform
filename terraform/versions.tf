terraform {
  required_version = ">= 1.0"
  
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
  
  # Optional: Use Terraform Cloud for state management
  # cloud {
  #   organization = "your-org-name"
  #   workspaces {
  #     name = "k8s-digitalocean"
  #   }
  # }
}