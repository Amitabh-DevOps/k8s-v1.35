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

# 4. Configure Kubernetes Apt Repository (v1.34)
echo "☸️ Configuring Kubernetes Apt Repository..."
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update

# 5. Install Kubectl, Kubeadm, Kubelet
echo "📦 Installing Kubernetes components (v1.34)..."
sudo apt-get install -y --allow-downgrades kubelet=1.34.0-1.1 kubeadm=1.34.0-1.1 kubectl=1.34.0-1.1
sudo apt-mark hold kubelet kubeadm kubectl
echo "✅ Kubernetes components installed and held at v1.34."

echo ""
echo "🎉 Setup Complete!"
echo "Next steps:"
echo "2. Run: kind create cluster --config kind-config.yaml --name upgrade-demo"
