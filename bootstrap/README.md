# Cluster Bootstrap

This directory contains scripts and manifests to bootstrap the EKS cluster with GitOps tooling (ArgoCD).

## Prerequisites

- Active `kubectl` context pointed to your EKS cluster.
- `jq` installed (optional, for JSON parsing).

## Install ArgoCD

Run the installation script:

```bash
chmod +x bootstrap/argocd/install.sh
./bootstrap/argocd/install.sh
```

This will:
1. Create the `argocd` namespace.
2. Install ArgoCD via official manifests.
3. Output the command to retrieve the initial admin password.
