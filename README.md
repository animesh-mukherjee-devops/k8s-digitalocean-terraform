# Automated Kubernetes Deployment on DigitalOcean

This comprehensive guide walks you through setting up automated Kubernetes deployment on DigitalOcean using Terraform and GitHub Actions. **The complete pipeline costs approximately $50-100/month for a basic production setup**, making it accessible for most teams while providing enterprise-grade automation.

DigitalOcean's 2025 platform offers significant enhancements including **1,000-node clusters, VPC-native networking, and scale-to-zero node pools** for cost optimization. Combined with Terraform Cloud's infrastructure management and GitHub Actions' robust CI/CD capabilities, this stack provides a modern, secure, and scalable deployment solution for production workloads.

## Why this stack excels for modern teams

**DigitalOcean Kubernetes Service (DOKS)** provides a **free control plane** with excellent performance and reliability, while **Terraform Cloud** offers infrastructure-as-code management with a generous free tier supporting up to 500 resources. **GitHub Actions** delivers native CI/CD integration with sophisticated secrets management and OIDC authentication for enhanced security. This combination eliminates vendor lock-in while maintaining enterprise-grade capabilities at a fraction of traditional cloud costs.

## Complete project structure

Before diving into setup, understand the complete project structure you'll create:

```
kubernetes-deployment/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml      # PR validation workflow
│       └── terraform-apply.yml     # Deployment workflow
├── terraform/
│   ├── main.tf                     # Primary Terraform configuration
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Output values
│   ├── versions.tf                 # Provider versions
│   └── terraform.tf                # Remote state configuration
├── k8s/
│   ├── namespace.yml               # Kubernetes namespaces
│   ├── deployment.yml              # Application deployments
│   └── service.yml                 # Kubernetes services
├── README.md                       # This documentation
└── .gitignore                      # Git ignore patterns
```

## Step 1: DigitalOcean account and API setup

### Creating your DigitalOcean account

DigitalOcean has evolved to a **team-based account structure** in 2025, providing better collaboration and billing management than traditional personal accounts.

1. **Register**: Visit `cloud.digitalocean.com/registrations/new`
2. **Account options**: Choose email/password or sign up using Google/GitHub SSO
3. **Team creation**: New signups automatically create a team account (replaces personal accounts)
4. **Email verification**: Complete the required email verification process
5. **Payment method**: Add a payment method for identity verification
6. **Welcome credit**: New accounts receive **$200 credit for the first 60 days** (increased from $100)

### Generating secure API tokens

Modern DigitalOcean tokens include enhanced security features including automatic GitHub scanning and granular scope controls.

**Generate your API token:**
1. Navigate to **API** section in the control panel left menu
2. Click **"Generate New Token"** in Personal Access Tokens section
3. Configure token settings:
   - **Token name**: Use descriptive names like "terraform-production"
   - **Expiration**: Set 90-day expiration (security best practice)
   - **Scopes**: Choose **Custom Scopes** and select only required permissions:
     - `kubernetes:create` and `kubernetes:read` for DOKS management
     - `droplet:create` and `droplet:read` for node pools
     - `load_balancer:create` for service exposure

**Security features in 2025:**
- **New token format**: Tokens use `dop_v1_` prefix for enhanced security
- **GitHub integration**: Automatic revocation if tokens are detected in public repositories
- **Usage tracking**: Last used timestamps help identify inactive tokens
- **Scope limitations**: Granular CRUD permissions prevent unauthorized access

**Store your token securely** - you'll need it for both Terraform Cloud and GitHub Actions configuration.

## Step 2: Terraform Cloud setup and authentication

### Account creation and initial setup

**Terraform Cloud is now HCP Terraform** as of April 2024, though functionality remains identical and the platform URL stays `app.terraform.io`.

1. **Create account**: Sign up at `https://app.terraform.io` with your preferred method
2. **Organization setup**: Create a new organization or join an existing one
3. **Project structure**: Configure projects for better workspace management (new in 2025)

### Authentication methods and security

**Choose the most secure authentication method:**

**OIDC/Dynamic Credentials (Recommended)**
- **Benefits**: Short-lived tokens, automatic rotation, enhanced security
- **Supported providers**: AWS, Google Cloud, Azure, HashiCorp Vault
- **Setup**: Configure trust relationships between HCP Terraform and your cloud provider

**API Tokens (Alternative)**
- **Team tokens**: Scoped to specific team access levels (recommended for automation)
- **User tokens**: Inherit user permissions, flexible but require careful management
- **Organization tokens**: Limited functionality, use only for initial setup

### Workspace configuration

**Create your workspace:**
1. Choose **VCS-driven workflow** for GitHub integration
2. Connect to your GitHub repository
3. Set workspace name: `digitalocean-kubernetes-prod`
4. Configure execution mode: **Remote** (recommended)
5. Set auto-apply: **Disabled** for production safety

**Configure variables:**
Navigate to workspace Variables tab and add:
- **Environment Variables**:
  - `DIGITALOCEAN_TOKEN`: Your DigitalOcean API token (mark as **Sensitive**)
  - `TF_VAR_cluster_name`: `production-cluster`
  - `TF_VAR_region`: `nyc1` (or your preferred region)

## Step 3: GitHub repository setup and secrets management

### Repository creation and structure

Create a new repository and establish the complete directory structure:

```bash
mkdir kubernetes-deployment
cd kubernetes-deployment
git init

# Create directory structure
mkdir -p .github/workflows terraform k8s
touch .github/workflows/{terraform-plan.yml,terraform-apply.yml}
touch terraform/{main.tf,variables.tf,outputs.tf,versions.tf,terraform.tf}
touch k8s/{namespace.yml,deployment.yml,service.yml}
```

### Secrets management hierarchy

GitHub provides **three levels of secrets** with specific precedence (environment secrets override repository secrets, which override organization secrets).

**Configure repository secrets:**
1. Navigate to repository **Settings > Secrets and variables > Actions**
2. Add **Repository secrets**:
   - `DIGITALOCEAN_TOKEN`: Your DigitalOcean API token
   - `TF_API_TOKEN`: Your Terraform Cloud team token
   - `TF_CLOUD_ORGANIZATION`: Your Terraform Cloud organization name

**Security best practices:**
- **Use descriptive names**: `PROD_DIGITALOCEAN_TOKEN` vs `DO_TOKEN`
- **Set expiration reminders**: Document token expiration dates
- **Separate environments**: Use different secrets for staging and production
- **Regular rotation**: Implement 90-day maximum token lifespans

### OIDC authentication setup (Advanced)

For enhanced security, configure OIDC authentication to eliminate long-lived secrets:

**Benefits:**
- **No stored credentials**: GitHub generates short-lived tokens automatically
- **Fine-grained permissions**: Cloud provider IAM controls access precisely
- **Automatic expiration**: Tokens expire after job completion

**Implementation requires:**
1. Cloud provider trust relationship configuration
2. Workflow permissions setup
3. Appropriate IAM role creation

## Complete file examples and configurations

### Terraform configuration files

**terraform/versions.tf**
```hcl
terraform {
  required_version = ">= 1.6"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.67"
    }
  }
}
```

**terraform/terraform.tf**
```hcl
terraform {
  cloud {
    organization = "your-organization-name"
    
    workspaces {
      name = "digitalocean-kubernetes-prod"
    }
  }
}
```

**terraform/variables.tf**
```hcl
variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "production-cluster"
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc1"
}

variable "node_size" {
  description = "Size of worker nodes"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.33.0-do.0"  # Latest as of 2025
}
```

**terraform/main.tf**
```hcl
# VPC for cluster networking
resource "digitalocean_vpc" "cluster_vpc" {
  name   = "${var.cluster_name}-vpc"
  region = var.region
}

# Kubernetes cluster with enhanced 2025 features
resource "digitalocean_kubernetes_cluster" "primary" {
  name   = var.cluster_name
  region = var.region
  version = var.kubernetes_version
  vpc_uuid = digitalocean_vpc.cluster_vpc.id

  # Enable high availability control plane for production
  ha = true

  node_pool {
    name       = "primary-pool"
    size       = var.node_size
    node_count = var.node_count
    
    # Enable autoscaling with scale-to-zero capability
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 10
    
    labels = {
      environment = "production"
      node-pool   = "primary"
    }
    
    taint {
      key    = "workload-type"
      value  = "general"
      effect = "NoSchedule"
    }
  }

  maintenance_policy {
    start_time = "04:00"
    day        = "sunday"
  }

  tags = ["kubernetes", "production", "terraform"]
}

# Load balancer for ingress traffic
resource "digitalocean_loadbalancer" "cluster_lb" {
  name   = "${var.cluster_name}-lb"
  region = var.region
  vpc_uuid = digitalocean_vpc.cluster_vpc.id

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
    path     = "/health"
  }

  tags = ["kubernetes", "production"]
}
```

**terraform/outputs.tf**
```hcl
output "cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.primary.id
}

output "cluster_urn" {
  description = "Uniform resource name of the cluster"
  value       = digitalocean_kubernetes_cluster.primary.urn
}

output "cluster_endpoint" {
  description = "Endpoint for the Kubernetes cluster"
  value       = digitalocean_kubernetes_cluster.primary.endpoint
}

output "kubeconfig" {
  description = "Kubeconfig for the cluster"
  value       = digitalocean_kubernetes_cluster.primary.kube_config.0.raw_config
  sensitive   = true
}

output "load_balancer_ip" {
  description = "Load balancer IP address"
  value       = digitalocean_loadbalancer.cluster_lb.ip
}
```

### GitHub Actions workflow files

**. github/workflows/terraform-plan.yml**
```yaml
name: 'Terraform Plan'

on:
  pull_request:
    branches: [main]
    paths: ['terraform/**']

env:
  TF_CLOUD_ORGANIZATION: "${{ secrets.TF_CLOUD_ORGANIZATION }}"
  TF_API_TOKEN: "${{ secrets.TF_API_TOKEN }}"
  TF_WORKSPACE: "digitalocean-kubernetes-prod"

permissions:
  contents: read
  pull-requests: write
  id-token: write

jobs:
  terraform:
    name: "Terraform Plan"
    runs-on: ubuntu-latest
    environment: staging

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.6.0
        cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}

    - name: Terraform Format Check
      run: terraform fmt -check -recursive
      working-directory: terraform

    - name: Terraform Init
      run: terraform init
      working-directory: terraform

    - name: Terraform Validate
      run: terraform validate
      working-directory: terraform

    - name: Security Scan with tfsec
      uses: aquasecurity/tfsec-action@v1.0.3
      with:
        working_directory: terraform
        
    - name: Terraform Plan
      id: plan
      run: |
        terraform plan -no-color -out=tfplan
        terraform show -no-color tfplan > plan_output.txt
      working-directory: terraform

    - name: Comment PR with Plan
      uses: actions/github-script@v7
      if: github.event_name == 'pull_request'
      with:
        script: |
          const fs = require('fs');
          const plan = fs.readFileSync('terraform/plan_output.txt', 'utf8');
          const output = `#### Terraform Plan 📋
          
          <details><summary>Show Plan Output</summary>
          
          \`\`\`terraform
          ${plan}
          \`\`\`
          
          </details>
          
          *Pushed by: @${{ github.actor }}, Action: \`${{ github.event_name }}\`*`;
          
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: output
          });
```

**. github/workflows/terraform-apply.yml**
```yaml
name: 'Terraform Apply'

on:
  push:
    branches: [main]
    paths: ['terraform/**']
  workflow_dispatch:

env:
  TF_CLOUD_ORGANIZATION: "${{ secrets.TF_CLOUD_ORGANIZATION }}"
  TF_API_TOKEN: "${{ secrets.TF_API_TOKEN }}"
  TF_WORKSPACE: "digitalocean-kubernetes-prod"
  DIGITALOCEAN_TOKEN: "${{ secrets.DIGITALOCEAN_TOKEN }}"

permissions:
  contents: read
  id-token: write

jobs:
  deploy:
    name: "Deploy Infrastructure"
    runs-on: ubuntu-latest
    environment: production
    
    concurrency:
      group: terraform-apply
      cancel-in-progress: false

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.6.0
        cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}

    - name: Terraform Init
      run: terraform init
      working-directory: terraform

    - name: Terraform Plan
      id: plan
      run: terraform plan -out=tfplan
      working-directory: terraform

    - name: Terraform Apply
      run: terraform apply tfplan
      working-directory: terraform

    - name: Install doctl
      uses: digitalocean/action-doctl@v2
      with:
        token: ${{ secrets.DIGITALOCEAN_TOKEN }}

    - name: Get kubeconfig
      run: |
        doctl kubernetes cluster kubeconfig save ${{ vars.CLUSTER_NAME }}
        kubectl cluster-info

    - name: Deploy Kubernetes resources
      run: |
        kubectl apply -f k8s/namespace.yml
        kubectl apply -f k8s/deployment.yml
        kubectl apply -f k8s/service.yml

    - name: Verify deployment
      run: |
        kubectl get pods -n production
        kubectl get services -n production
```

### Kubernetes resource files

**k8s/namespace.yml**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: production
    managed-by: terraform
---
apiVersion: v1
kind: Namespace
metadata:
  name: staging
  labels:
    environment: staging
    managed-by: terraform
```

**k8s/deployment.yml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-application
  namespace: production
  labels:
    app: web-application
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-application
  template:
    metadata:
      labels:
        app: web-application
        version: v1
    spec:
      containers:
      - name: web
        image: nginx:1.21.6-alpine
        ports:
        - containerPort: 80
          name: http
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
          capabilities:
            drop:
            - ALL
            add:
            - NET_BIND_SERVICE
        livenessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
      tolerations:
      - key: "workload-type"
        operator: "Equal"
        value: "general"
        effect: "NoSchedule"
```

**k8s/service.yml**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-application-service
  namespace: production
  labels:
    app: web-application
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: web-application
---
apiVersion: v1
kind: Service
metadata:
  name: web-application-internal
  namespace: production
  labels:
    app: web-application
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: web-application
```

### Additional configuration files

**.gitignore**
```gitignore
# Terraform files
*.tfstate
*.tfstate.backup
.terraform/
.terraform.lock.hcl
terraform.tfplan
terraform.tfplan.json

# Kubernetes
kubeconfig
*.kubeconfig

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db

# Logs
*.log

# Temporary files
*.tmp
*.temp
```

## Step-by-step deployment instructions

### Initial deployment process

**1. Repository setup**
```bash
# Clone your repository
git clone https://github.com/your-username/kubernetes-deployment.git
cd kubernetes-deployment

# Create all files from examples above
# Commit initial configuration
git add .
git commit -m "Initial Terraform and GitHub Actions configuration"
git push origin main
```

**2. Terraform Cloud integration**
- Navigate to your Terraform Cloud workspace
- Verify VCS connection is working
- Check that variables are properly configured
- Ensure workspace can access your repository

**3. First deployment**
```bash
# Create feature branch for initial deployment
git checkout -b feature/initial-setup

# Make any necessary adjustments to variables
# Create pull request to trigger plan workflow
git add .
git commit -m "Configure initial cluster deployment"
git push origin feature/initial-setup
```

**4. Review and merge**
- Create pull request in GitHub
- Review Terraform plan output in PR comments
- Verify security scan passes
- Merge to main branch to trigger deployment

**5. Verify deployment**
```bash
# Install local tools
# kubectl and doctl installation (see troubleshooting section)

# Connect to cluster
doctl auth init --access-token YOUR_TOKEN
doctl kubernetes cluster kubeconfig save YOUR_CLUSTER_NAME

# Verify cluster connectivity
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
```

### Managing updates and changes

**Infrastructure changes:**
1. Create feature branch for changes
2. Modify Terraform configuration
3. Create pull request
4. Review plan output
5. Merge to deploy changes

**Application updates:**
1. Update Kubernetes manifests in `k8s/` directory
2. Push changes to main branch
3. GitHub Actions applies changes automatically
4. Verify deployment with `kubectl get pods`

## Troubleshooting common issues

### Cluster connection problems

**Issue: kubectl connection refused**
```bash
# Check cluster status
doctl kubernetes cluster list
doctl kubernetes cluster get YOUR_CLUSTER_NAME

# Download fresh kubeconfig
doctl kubernetes cluster kubeconfig save YOUR_CLUSTER_NAME

# Verify kubectl context
kubectl config current-context
kubectl config get-contexts
```

**Issue: Network/firewall blocking access**
- Corporate networks often block Kubernetes API ports (6443)
- Try connecting via mobile hotspot or VPN
- Check with IT department about firewall rules
- Verify DigitalOcean API access is not blocked

### Terraform deployment failures

**Issue: Resource quota exceeded**
```bash
# Check current resource usage
doctl compute droplet list
doctl kubernetes cluster list

# Verify account limits
# Contact DigitalOcean support for limit increases if needed
```

**Issue: State lock errors**
```bash
# Check Terraform Cloud workspace for active runs
# Cancel stuck runs through Terraform Cloud UI if necessary
# Retry deployment after confirming no active runs
```

### GitHub Actions workflow problems

**Issue: Secrets not accessible**
- Verify repository secrets are correctly named
- Check that secrets are available in correct environment
- Ensure workflow has proper permissions

**Issue: OIDC authentication failures**
```yaml
# Verify workflow permissions include id-token: write
permissions:
  id-token: write
  contents: read
```

### Pod scheduling and resource issues

**Issue: Pods pending due to insufficient resources**
```bash
# Check node resources
kubectl describe nodes
kubectl top nodes

# Scale node pool if needed
doctl kubernetes cluster node-pool create YOUR_CLUSTER_NAME \
  --name additional-pool \
  --size s-4vcpu-8gb \
  --count 2 \
  --auto-scale \
  --min-nodes 1 \
  --max-nodes 5
```

**Issue: Toleration and taint mismatches**
- Verify pod tolerations match node taints
- Check node labels and selectors
- Review scheduling constraints

### Load balancer and networking issues

**Issue: Load balancer health checks failing**
```bash
# Check service configuration
kubectl describe service YOUR_SERVICE_NAME

# Verify pod health and readiness
kubectl describe pod YOUR_POD_NAME

# Check load balancer status
doctl compute load-balancer list
doctl compute load-balancer get YOUR_LB_ID
```

## Cost considerations and optimization

### Current pricing structure (2025)

**DigitalOcean Kubernetes costs:**
- **Control plane**: FREE (fully managed)
- **High availability control plane**: $40/month
- **Worker nodes**: Same pricing as Droplets
  - Basic (1 vCPU, 512MB): $4/month
  - General purpose (2 vCPUs, 4GB): $24/month  
  - CPU-optimized (8 vCPUs, 32GB): $189/month
- **Load balancers**: $12/month each
- **Block storage**: $10/month per 100GB

**Terraform Cloud costs:**
- **Free tier**: Up to 500 resources
- **Standard tier**: $0.00014/hour per resource beyond 500
- **Example**: 1,000 resources ≈ $350/month

**GitHub Actions costs:**
- **Public repositories**: Unlimited minutes
- **Private repositories**: 2,000 free minutes/month
- **Overage**: $0.008/minute for Linux runners

### Cost optimization strategies

**Cluster optimization:**
- **Use cluster autoscaler** to scale nodes based on actual demand
- **Enable scale-to-zero** for development node pools
- **Right-size node types** based on workload requirements
- **Implement resource requests and limits** to maximize node utilization

**Storage and networking:**
- **Minimize load balancers** by using ingress controllers
- **Use internal services** for inter-service communication
- **Right-size persistent volumes** to avoid overprovisioning
- **Leverage free bandwidth allowances** (2,000GB/month per node)

**Development workflow optimization:**
- **Use path-based triggers** to avoid unnecessary workflow runs
- **Implement workflow caching** to reduce execution time
- **Optimize Docker builds** with multi-stage builds and layer caching
- **Consider self-hosted runners** for high-volume usage

### Budget planning examples

**Small team setup (3-node cluster):**
- 3x General Purpose nodes: $72/month
- 1x Load balancer: $12/month
- Block storage (300GB): $30/month
- **Total**: ~$114/month

**Medium team setup (5-node cluster with HA):**
- 5x General Purpose nodes: $120/month
- HA control plane: $40/month
- 2x Load balancers: $24/month
- Block storage (500GB): $50/month
- Terraform Cloud (800 resources): ~$300/month
- **Total**: ~$534/month

## Security best practices implementation

### Token management security

**API token security:**
- **Rotate tokens every 90 days maximum**
- **Use scoped tokens** with minimal required permissions
- **Store tokens in GitHub Secrets** or Terraform Cloud variables
- **Never commit tokens** to version control
- **Monitor token usage** through platform audit logs

**GitHub repository security:**
```yaml
# Enable branch protection rules
- Require pull request reviews before merging
- Require status checks to pass before merging
- Require up-to-date branches before merging
- Include administrators in restrictions

# Configure environment protection rules
- Required reviewers for production deployments
- Wait timers before sensitive deployments
- Branch restrictions for environment access
```

### Kubernetes cluster security

**Pod security standards:**
```yaml
# Apply pod security admission policies
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

**RBAC implementation:**
```yaml
# Create service accounts with minimal permissions
apiVersion: v1
kind: ServiceAccount
metadata:
  name: deployment-sa
  namespace: production
automountServiceAccountToken: false
---
# Grant specific permissions only
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: deployment-role
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "patch"]
```

### Network security measures

**VPC-native clusters** (default in 2025):
- Enhanced network isolation from internet
- Native routing between cluster and VPC resources
- Support for VPC peering across regions
- Managed Cilium for advanced networking capabilities

**Network policies:**
```yaml
# Implement default deny-all policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

## Connecting to deployed clusters locally

### Prerequisites installation

**Install required tools:**
```bash
# Install kubectl (latest version)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install doctl (DigitalOcean CLI)
curl -sL https://github.com/digitalocean/doctl/releases/download/v1.141.0/doctl-1.141.0-linux-amd64.tar.gz | tar -xzv
sudo mv doctl /usr/local/bin/

# Install Helm (optional but recommended)
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# Verify installations
kubectl version --client
doctl version
helm version
```

### Authentication and connection

**Connect to your cluster:**
```bash
# Authenticate with DigitalOcean
doctl auth init --access-token YOUR_DIGITALOCEAN_TOKEN

# List available clusters
doctl kubernetes cluster list

# Download kubeconfig for your cluster
doctl kubernetes cluster kubeconfig save YOUR_CLUSTER_NAME

# Verify connection
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces
```

### Multiple environment management

**Managing multiple clusters:**
```bash
# Set up different contexts for environments
kubectl config set-context production --cluster=prod-cluster --user=prod-user
kubectl config set-context staging --cluster=staging-cluster --user=staging-user

# Switch between contexts
kubectl config use-context production
kubectl config current-context

# View all available contexts
kubectl config get-contexts

# Rename contexts for clarity
kubectl config rename-context do-nyc1-production-cluster production
kubectl config rename-context do-nyc1-staging-cluster staging
```

## Cleanup and maintenance procedures

### Automated resource cleanup

**Implement cleanup strategies early** to prevent unnecessary costs and resource accumulation:

**Time-based cleanup with CronJobs:**
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cleanup-old-resources
  namespace: production
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: cleanup
            image: bitnami/kubectl
            command:
            - /bin/sh
            - -c
            - |
              # Clean up completed jobs older than 24 hours
              kubectl delete jobs --field-selector status.successful=1 \
                --all-namespaces \
                --timeout=60s
              
              # Clean up failed pods older than 48 hours
              kubectl get pods --all-namespaces --field-selector=status.phase=Failed \
                -o json | jq -r '.items[] | select(.metadata.creationTimestamp | fromdateiso8601 < (now - 172800)) | "\(.metadata.namespace) \(.metadata.name)"' | \
                while read namespace name; do kubectl delete pod $name -n $namespace; done
          restartPolicy: OnFailure
```

### Infrastructure maintenance

**Regular maintenance tasks:**

**Weekly maintenance:**
```bash
# Update cluster to latest supported Kubernetes version
doctl kubernetes cluster upgrade YOUR_CLUSTER_NAME --version=1.33.0-do.0

# Review resource utilization
kubectl top nodes
kubectl top pods --all-namespaces --sort-by=memory

# Check for unused PersistentVolumes
kubectl get pv --sort-by=.metadata.creationTimestamp

# Review security policies and compliance
kubectl get networkpolicies --all-namespaces
kubectl get podsecuritypolicies
```

**Monthly maintenance:**
```bash
# Rotate API tokens
# Update tokens in GitHub Secrets and Terraform Cloud
# Test all workflows after rotation

# Review and update container images
# Check for security updates
# Update base images in Dockerfiles

# Audit resource costs and optimization opportunities
doctl invoice list
doctl kubernetes cluster list --format Name,Memory,VCPUs,Price
```

### Disaster recovery procedures

**Backup critical resources:**
```bash
# Backup Kubernetes resources
kubectl get all --all-namespaces -o yaml > cluster-backup-$(date +%Y%m%d).yaml

# Backup persistent volume data
kubectl get pv -o yaml > persistent-volumes-$(date +%Y%m%d).yaml

# Export Terraform state (handled automatically by Terraform Cloud)
# Ensure state backups are enabled in workspace settings
```

**Recovery procedures:**
```bash
# Recreate cluster from Terraform configuration
terraform plan -out=recovery.tfplan
terraform apply recovery.tfplan

# Restore Kubernetes resources
kubectl apply -f cluster-backup-YYYYMMDD.yaml

# Verify services and connectivity
kubectl get pods --all-namespaces
kubectl get services --all-namespaces
```

### Environment lifecycle management

**Development environment cleanup:**
```bash
# Automate cleanup of PR environments
# Add to GitHub Actions workflow on PR close
- name: Cleanup PR Environment
  if: github.event.action == 'closed'
  run: |
    kubectl delete namespace pr-${{ github.event.number }} || true
    # Clean up any PR-specific resources
```

**Resource monitoring and alerting:**
```bash
# Set up monitoring for resource thresholds
# Monitor node utilization, pod resource consumption
# Implement alerting for cost thresholds
# Regular reviews of unused resources
```

This comprehensive guide provides a complete foundation for automated Kubernetes deployment on DigitalOcean using modern DevOps practices. The combination of **infrastructure-as-code with Terraform**, **robust CI/CD with GitHub Actions**, and **DigitalOcean's enhanced 2025 Kubernetes features** creates a powerful, scalable, and cost-effective deployment solution.

**Regular maintenance, security reviews, and cost optimization** ensure your infrastructure remains secure, efficient, and aligned with your organization's needs as it grows.