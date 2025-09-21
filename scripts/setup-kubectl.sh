#!/bin/bash

set -e  # Exit on any error

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install doctl (DigitalOcean CLI)
cd /tmp
wget https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.104.0-linux-amd64.tar.gz
tar xf doctl-1.104.0-linux-amd64.tar.gz
sudo mv doctl /usr/local/bin/

# Authenticate doctl (token should be passed as environment variable)
if [ -z "$DIGITALOCEAN_TOKEN" ]; then
    echo "Error: DIGITALOCEAN_TOKEN environment variable is not set"
    exit 1
fi

doctl auth init --access-token "$DIGITALOCEAN_TOKEN"

# Get kubeconfig from Terraform output
cd "$GITHUB_WORKSPACE/terraform"
CLUSTER_ID=$(terraform output -raw cluster_id)
doctl kubernetes cluster kubeconfig save "$CLUSTER_ID"

# Test connection
kubectl cluster-info
kubectl get nodes