#!/bin/bash

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install doctl (DigitalOcean CLI)
cd /tmp
wget https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.104.0-linux-amd64.tar.gz
tar xf doctl-1.104.0-linux-amd64.tar.gz
sudo mv doctl /usr/local/bin/

# Authenticate doctl
doctl auth init --access-token $DIGITALOCEAN_TOKEN

# Get kubeconfig from Terraform output
cd terraform
CLUSTER_ID=$(terraform output -raw cluster_id)
doctl kubernetes cluster kubeconfig save $CLUSTER_ID

# Test connection
kubectl cluster-info
kubectl get nodes