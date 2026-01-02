#!/bin/bash
set -e

echo "🚀 Starting Kubernetes Environment Setup for Ubuntu..."

# 1. Update system
sudo apt update
sudo apt upgrade -y

# 2. Install Docker
echo "🐳 Installing Docker..."
sudo apt install -y docker.io
sudo usermod -aG docker $USER
echo "✅ Docker installed. (You may need to logout and back in for group changes to take effect)"

# 3. Install Kind
echo "🏗️ Installing Kind..."
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.25.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
echo "✅ Kind installed."

# 4. Install Kubectl
echo "☸️ Installing Kubectl..."
K8S_VERSION="v1.34.0"
curl -LO "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
echo "✅ Kubectl (${K8S_VERSION}) installed."

echo ""
echo "🎉 Setup Complete!"
echo "Next steps:"
echo "1. Run: source ~/.bashrc or logout/login"
echo "2. Run: kind create cluster --config kind-config.yaml --name upgrade-demo"
