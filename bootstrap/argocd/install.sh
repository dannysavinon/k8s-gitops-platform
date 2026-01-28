#!/bin/bash
set -e

echo "Starting ArgoCD Installation..."

# 1. Create Namespace
echo "Creating 'argocd' namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# 2. Install ArgoCD Stable
echo "Applying ArgoCD Manifests..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Wait for Server to be Rollout
echo "Waiting for ArgoCD Server to be ready..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

echo "ArgoCD Installed Successfully!"
echo "----------------------------------------------------"
echo "Access ArgoCD UI:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "Initial Admin Password:"
echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "----------------------------------------------------"
