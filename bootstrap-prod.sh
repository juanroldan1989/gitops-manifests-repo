#!/bin/bash

set -euo pipefail

# === CONFIG ===
CLUSTER_NAME="prod-eks-cluster-a"
REGION="us-east-1"
AWS_PROFILE="default"
APPS_FOLDER="argo/apps"
APPS_TO_INSTALL=()

# === Parse CLI arguments ===
if [[ "$1" == "--apps" ]]; then
  shift
  APPS_TO_INSTALL=("$@")
fi

# == Step 0: Provision AWS VPC and EKS Cluster ==
# Steps within `/infrastructure/environments/prod/README.md`

# === Step 1: Read Cluster Name and update Kubec Config ===
echo "> Reading Cluster Name ..."
echo "> Updating kubeconfig for cluster: $CLUSTER_NAME"
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"
if [[ $? -ne 0 ]]; then
  echo "❌ Failed to update kubeconfig for cluster '$CLUSTER_NAME'"
  exit 1
fi
echo "> Kubeconfig updated successfully"

# === Step 2: Check if kubectl is configured correctly ===
if ! kubectl get nodes &>/dev/null; then
  echo "❌ kubectl is not configured correctly. Please check your kubeconfig."
  exit 1
fi
echo "> kubectl is configured correctly"

# === Step 3: Extract AWS credentials and create Kubernetes secret ===
echo "> Reading AWS credentials from ~/.aws/credentials using profile: $AWS_PROFILE"
ACCESS_KEY=$(aws configure get aws_access_key_id --profile "$AWS_PROFILE")
SECRET_KEY=$(aws configure get aws_secret_access_key --profile "$AWS_PROFILE")

if [[ -z "$ACCESS_KEY" || -z "$SECRET_KEY" ]]; then
  echo "❌ AWS credentials not found for profile '$AWS_PROFILE'"
  exit 1
fi

# === Step 4: Create required namespaces ===
echo "> Creating required namespaces"
kubectl create ns argocd || true
kubectl create ns external-secrets || true

# === Step 5: Create AWS credential secret ===
echo "> Creating AWS credential secret in Kubernetes (only if not already created)"

kubectl create secret generic awssm-secret \
  --namespace external-secrets \
  --from-literal=access-key="$ACCESS_KEY" \
  --from-literal=secret-access-key="$SECRET_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

# === Step 6: Install core tools ===
echo "> Installing ArgoCD (only if not already installed)"
if ! kubectl get pods -n argocd | grep -q argocd-server; then
  echo "➡️ ArgoCD not found, installing..."
  helm repo add argo https://argoproj.github.io/argo-helm
  helm repo update
  helm install argocd argo/argo-cd --namespace argocd --create-namespace -f argo/config/values.yaml
else
  echo "➡️ ArgoCD already installed, skipping..."
fi

# === Step 6: Install ESO via ArgoCD ===
echo "> Installing External Secrets Operator (ESO) via ArgoCD"
kubectl apply -f argo/apps/eso.yaml
kubectl apply -f argo/apps/eso-config.yaml

# === Step 7: Install Applications via ArgoCD ===
echo "> Installing apps via ArgoCD"

if [ ${#APPS_TO_INSTALL[@]} -eq 0 ]; then
  echo "➡️ No app names provided, installing ALL apps from $APPS_FOLDER"
  for app in "$APPS_FOLDER"/*.yaml; do
    echo "⏳ Installing app: $app"
    kubectl apply -f "$app"
  done
else
  for app_name in "${APPS_TO_INSTALL[@]}"; do
    app_file="$APPS_FOLDER/${app_name}.yaml"
    if [[ -f "$app_file" ]]; then
      echo "⏳ Installing app: $app_name"
      kubectl apply -f "$app_file"
    else
      echo "⚠️ App manifest not found: $app_file"
    fi
  done
fi

echo "✅ Cluster '$CLUSTER_NAME' fully bootstrapped with ArgoCD, ESO and Applications"
