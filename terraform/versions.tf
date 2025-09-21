terraform {
  required_version = ">= 1.0"
  
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  
  cloud {
    organization = "k8s-digitalocean"  # Replace with your actual org name
    workspaces {
      name = "k8s-digitalocean"
    }
  }
}