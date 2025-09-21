# 🛠️ k8s-digitalocean-terraform

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](#license)  
[![Terraform Version](https://img.shields.io/badge/Terraform-%3E%3D1.6.0-blue)](#terraform-version)  
[![DO Provider](https://img.shields.io/badge/DigitalOcean‑Provider‑%3E%3D2.67‑0‑%2FDA‑latest‑stable‑green)](#terraform-provider)  
[![GitHub Actions Status](https://github.com/animesh-mukherjee-devops/k8s-digitalocean-terraform/workflows/Terraform%20Apply/badge.svg)](#github-actions-workflows)  

---

## Table of Contents

1. [Project Overview](#project-overview)  
2. [Why This Stack](#why-this-stack)  
3. [Repository Structure](#repository-structure)  
4. [Prerequisites](#prerequisites)  
5. [Setup & Configuration Steps](#setup--configuration-steps)  
   - [DigitalOcean Account & API Token](#digitalocean-account--api-token)  
   - [Terraform Cloud / Remote State](#terraform-cloud--remote-state)  
   - [GitHub Repository & Secrets](#github-repository--secrets)  
6. [Workflows / CI‑CD](#workflows--ci‑cd)  
7. [Usage](#usage)  
   - [Initial Deployment](#initial-deployment)  
   - [Modifying Infrastructure](#modifying-infrastructure)  
   - [Deploying Kubernetes Manifests](#deploying-kubernetes-manifests)  
8. [Troubleshooting](#troubleshooting)  
9. [Security Best Practices](#security-best-practices)  
10. [Cost & Optimization](#cost-and-optimization)  
11. [Cleanup & Maintenance](#cleanup--maintenance)  
12. [License](#license)  

---

## Project Overview

This repo implements infrastructure‑as‑code to provision a Kubernetes (DOKS) cluster on **DigitalOcean**, using **Terraform**, with automated workflows via **GitHub Actions**. It includes:

- Configurable Terraform modules for cluster creation, VPC / networking, node pools.  
- Kubernetes manifest files for application deployment.  
- GitHub Actions for *plan* (on pull requests) and *apply* (on main branch / manual trigger).  
- Sensible defaults, security scans, version pinning, etc.

---

## Why This Stack

- **Managed Kubernetes** with DigitalOcean (DOKS): simpler control plane, built‑in features.  
- **Terraform**: declarative infra, versioned, reproducible.  
- **Remote state / Terraform Cloud**: collaboration, state locking, security.  
- **GitHub Actions**: native CI/CD, integrated with secrets, workflows, etc.  
- Extensible: can incorporate environments (staging, production), autoscaling, advanced security features.

---

## Repository Structure

```
k8s-digitalocean-terraform/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml       # Plan workflow (PR validation)
│       └── terraform-apply.yml      # Apply workflow (main branch / manual)
├── scripts/                         # Helper scripts (if any)
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   └── terraform.tf                 # remote state / workspace config
├── k8s/
│   ├── namespace.yml
│   ├── deployment.yml
│   └── service.yml
├── .gitignore
└── README.md
```

---

## Prerequisites

- Terraform ≥ **1.6.0**  
- DigitalOcean account & API token with sufficient permissions  
- Terraform Cloud account / remote state setup (or other remote backend)  
- `doctl` CLI (optional, for local verification)  
- `kubectl` CLI (for deploying & verifying manifests)  

---

## Setup & Configuration Steps

### DigitalOcean Account & API Token

1. Sign up / log in to DigitalOcean.  
2. Generate an API token (e.g. **Personal Access Token**) with minimal required scopes (Kubernetes cluster create, node pools, load balancers, networking).  
3. Securely store the token (don’t commit to repo).

### Terraform Cloud / Remote State

1. Create or use an organization on Terraform Cloud.  
2. Create a workspace (e.g. `digitalocean-kubernetes-prod`).  
3. Connect the workspace with your GitHub repo.  
4. Set appropriate execution mode (Remote) and auto‑apply rules (you may want to disable auto‑apply for prod).  
5. Define necessary variables:
   - `DIGITALOCEAN_TOKEN` (sensitive)  
   - `TF_VAR_cluster_name`, `TF_VAR_region`, `TF_VAR_node_size`, `TF_VAR_node_count`, etc.  

### GitHub Repository & Secrets

1. Push code to GitHub in this repository.  
2. Under **Settings → Secrets & variables → Actions**, add:
   - `DIGITALOCEAN_TOKEN`  
   - `TF_API_TOKEN` (if using Terraform Cloud)  
   - `TF_CLOUD_ORGANIZATION`  
   - Any other needed environment‑specific vars  
3. Setup branch protection rules on `main`: require PR review, passing workflows, etc.

---

## Workflows / CI‑CD

There are two main GitHub Actions workflows:

| Workflow | Trigger                        | Purpose                                           |
|---------|----------------------------------|---------------------------------------------------|
| **Terraform Plan** | On pull request against `main`, changes in `terraform/**` | Validate syntax, formatting, run `terraform plan`, comment plan output in PR |
| **Terraform Apply** | On push to `main` (changes in `terraform/**`), or manual dispatch | Actually apply infrastructure changes, deploy Kubernetes manifests |

Key features:

- Terraform format check / validate  
- Security scan (e.g. `tfsec`)  
- Remote state locking via Terraform Cloud  
- Permissions / environments (e.g. “production”) enforced  

---

## Usage

### Initial Deployment

```bash
git clone https://github.com/animesh-mukherjee-devops/k8s-digitalocean-terraform.git
cd k8s-digitalocean-terraform
# Adjust any variable defaults in terraform/variables.tf
git checkout -b feature/initial-setup
# Make changes, commit, push
```

- Open PR → this triggers `terraform-plan` workflow  
- Review plan output + security scan  
- Merge to `main` → triggers `terraform-apply`

### Modifying Infrastructure

- Create feature branch  
- Update Terraform `.tf` files  
- Submit PR → review plan  
- After merge, changes auto‑applied

### Deploying Kubernetes Manifests

- Edit files in `k8s/` (namespace, deployment, service)  
- Those are applied during the `terraform-apply` workflow after infra is up  
- You can also manually run via `kubectl` with correct kubeconfig

---

## Troubleshooting

| Problem | Possible Cause | Solution |
|---------|------------------|----------|
| `kubectl` cannot connect / cluster not responding | Kubeconfig misconfigured, cluster not up, permissions | Use `doctl` to fetch kubeconfig, verify cluster exists |
| Terraform errors (plan/apply) | Missing vars, invalid configs, API rate/limits | Double‑check variable values, DigitalOcean quotas, Terraform provider versions |
| Secrets missing in workflows | Names mis‑matched, permissions not set | Check in GitHub settings, ensure secrets are available to Actions, ensure workflows request correct permissions |
| Workflow failing tfsec or fmt/validate | Code style / security issues | Fix violations, re‑run checks locally before pushing PR |

---

## Security Best Practices

- Use **least privilege** for API tokens  
- Rotate secrets / tokens periodically  
- Use remote state backend with locking & encryption (Terraform Cloud)  
- Enforce branch protections, enforce required reviews  
- If possible, use OIDC / short‑lived credentials instead of long‑lived ones  
- Validate Kubernetes manifests for security (pod security admission, RBAC, image scanning)  

---

## Cost & Optimization

- DigitalOcean Kubernetes control plane is free, but high‑availability control plane costs extra  
- Choose node sizes carefully — match workload needs vs cost  
- Use autoscaling / scale to zero for workloads where possible  
- Limit the number of load balancers; use ingress controllers instead where possible  
- Delete unused resources (volumes, node pools, etc.)  

---

## Cleanup & Maintenance

- Periodically upgrade Kubernetes version to latest supported by DOKS  
- Review unused resources (volumes, load balancers, etc.)  
- Backup Kubernetes manifests & state  
- Monitor costs, usage, alerts  
- Ensure workflows & dependencies remain up to date  

---

## Terraform Version & Provider

| Component     | Version Required / Used         |
|----------------|-----------------------------------|
| Terraform      | ≥ **1.6.0**                       |
| DigitalOcean provider | ≥ **2.67.0**          |
| Other tools    | `doctl`, `kubectl`               |

---

## GitHub Actions Permissions

Make sure workflows have:

- `id-token: write` permission (for OIDC if using)  
- `contents: read` or `pull‑requests: write`, etc., as needed  
- Secrets accessible and named correctly  

---

## License

This project is licensed under the **MIT License**. See [LICENSE](LICENSE) for details.

---

## Contributors

- **Animesh Mukherjee** – Initial work  
- Feel free to open issues / PRs for improvements  

---

## Contact

If you have questions, feature requests, or issues, please open an issue in this repository.
