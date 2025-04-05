#!/bin/bash

set -euo pipefail

# === CONFIG ===
APPS_FOLDER="argo/apps"
AWS_PROFILE="default"
REGION="us-east-1"
CLUSTER_NAME=""
ARGOCD_VALUES="bootstrap/argo/values.yaml"
APPS_TO_INSTALL=()

# === Parse CLI arguments ===
usage() {
  echo "Usage: $0 --cluster-name <name> [--apps app1 app2 ...]"
  exit 1
}

if [[ $# -lt 2 ]]; then
  usage
fi

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --cluster-name)
      CLUSTER_NAME="$2"
      shift; shift
      ;;
    --apps)
      shift
      while [[ $# -gt 0 && ! $1 == --* ]]; do
        APPS_TO_INSTALL+=("$1")
        shift
      done
      ;;
    *)
      usage
      ;;
  esac
done

if [[ -z "$CLUSTER_NAME" ]]; then
  echo "❌ --cluster-name is required."
  usage
fi

# === Step: Check cluster access ===
echo "> Verifying access to cluster: $CLUSTER_NAME"
if ! kubectl get nodes &>/dev/null; then
  echo "❌ kubectl is not configured correctly. Check your kubeconfig."
  exit 1
fi

echo "> Cluster '$CLUSTER_NAME' is reachable"

# === Step: Fetch AWS credentials ===
echo "> Reading AWS credentials from profile: $AWS_PROFILE"
ACCESS_KEY=$(aws configure get aws_access_key_id --profile "$AWS_PROFILE")
SECRET_KEY=$(aws configure get aws_secret_access_key --profile "$AWS_PROFILE")

if [[ -z "$ACCESS_KEY" || -z "$SECRET_KEY" ]]; then
  echo "❌ AWS credentials not found for profile '$AWS_PROFILE'"
  exit 1
fi

# === Step: Create required namespaces ===
echo "> Creating required namespaces"
kubectl create ns argocd || true
kubectl create ns argo-rollouts || true
kubectl create ns external-secrets || true

# === Step: Create AWS credential secret ===
echo "> Creating AWS secret for ESO"
kubectl create secret generic awssm-secret \
  --namespace external-secrets \
  --from-literal=access-key="$ACCESS_KEY" \
  --from-literal=secret-access-key="$SECRET_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

# === Step: Install ArgoCD ===
echo "> Installing ArgoCD via Helm"
helm repo add argo https://argoproj.github.io/argo-helm || true
helm repo update

if ! kubectl get pods -n argocd | grep -q argocd-server; then
  helm install argocd argo/argo-cd --namespace argocd --create-namespace -f "$ARGOCD_VALUES"
else
  echo "➡️ ArgoCD already installed, skipping..."
fi

# === Step: Install ESO ===
echo "> Installing External Secrets Operator"
kubectl apply -f argo/apps/eso.yaml
kubectl apply -f argo/apps/eso-config.yaml

# === Step: Install Applications ===
echo "> Installing Applications"
if [ ${#APPS_TO_INSTALL[@]} -eq 0 ]; then
  echo "➡️ No specific apps provided. Installing ALL apps in $APPS_FOLDER"
  for app in "$APPS_FOLDER"/*.yaml; do
    echo "⏳ Installing: $app"
    kubectl apply -f "$app"
  done
else
  for app_name in "${APPS_TO_INSTALL[@]}"; do
    app_file="$APPS_FOLDER/${app_name}.yaml"
    if [[ -f "$app_file" ]]; then
      echo "⏳ Installing: $app_file"
      kubectl apply -f "$app_file"
    else
      echo "⚠️ App not found: $app_file"
    fi
  done
fi

echo "✅ Cluster '$CLUSTER_NAME' bootstrapped with ArgoCD, ESO and applications."
