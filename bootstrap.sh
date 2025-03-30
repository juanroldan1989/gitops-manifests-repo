#!/bin/bash

set -euo pipefail

# === CONFIG ===
CLUSTER_NAME="gitops-dev"
AWS_PROFILE="default"
APPS_FOLDER="argo/apps"
APPS_TO_INSTALL=()

# === Parse CLI arguments ===
if [[ "$1" == "--apps" ]]; then
  shift
  APPS_TO_INSTALL=("$@")
fi

# === Step 1: Create Kind Cluster ===
echo "> Creating Kind cluster: $CLUSTER_NAME"
cat <<EOF | kind create cluster --name "$CLUSTER_NAME" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
  - role: worker
  - role: worker
EOF

# === Step 2: Extract AWS credentials and create Kubernetes secret ===
echo "> Reading AWS credentials from ~/.aws/credentials using profile: $AWS_PROFILE"
ACCESS_KEY=$(aws configure get aws_access_key_id --profile "$AWS_PROFILE")
SECRET_KEY=$(aws configure get aws_secret_access_key --profile "$AWS_PROFILE")

if [[ -z "$ACCESS_KEY" || -z "$SECRET_KEY" ]]; then
  echo "❌ AWS credentials not found for profile '$AWS_PROFILE'"
  exit 1
fi

# === Step 3: Create required namespaces ===
echo "> Creating required namespaces"
kubectl create ns argocd || true
kubectl create ns argo-rollouts || true
kubectl create ns external-secrets || true

# === Step 4: Create AWS credential secret ===
echo "> Creating AWS credential secret in Kubernetes"
kubectl create secret generic awssm-secret \
  -n external-secrets \
  --from-literal=access-key="$ACCESS_KEY" \
  --from-literal=secret-access-key="$SECRET_KEY"

# === Step 5: Install core tools ===
echo "> Installing ArgoCD"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "> Installing ArgoRollouts"
kubectl apply -n argo-rollouts -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml
kubectl apply -n argo-rollouts -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/dashboard-install.yaml

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

echo "✅ Cluster '$CLUSTER_NAME' fully bootstrapped with ArgoCD, ESO, ArgoRollouts and Applications"
