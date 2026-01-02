# Kubernetes Cluster Upgrade Demonstration: v1.34 to v1.35

This repository provides a comprehensive environment and application to demonstrate a live Kubernetes cluster upgrade. It is specifically designed to showcase the transition from version 1.34 to 1.35 using a multi-node Kind cluster running on an AWS EC2 Ubuntu instance.

The project includes a "Cluster Monitor" application that provides real-time visual telemetry of pod distribution across nodes, making it an ideal tool for demonstrating zero-downtime upgrades and pod rescheduling.

## Project Structure

- **Application**: A Node.js Express server with a high-performance telemetry dashboard.
- **Containerization**: A multi-stage Dockerfile for an optimized runtime environment.
- **Orchestration**: Kubernetes manifests defining a NodePort service and a Deployment with three replicas.
- **Infrastructure**: Kind configuration for a 3-node cluster and an automated setup script for Ubuntu.

## Environment Preparation (Run on AWS EC2 Host)

Before beginning the demonstration, prepare the host environment by installing the necessary tools.

1. Execute the setup script:
   ```bash
   chmod +x setup-k8s.sh
   ./setup-k8s.sh
   ```

2. Refresh group membership for Docker (if not already done):
   ```bash
   newgrp docker
   ```

3. Initialize the v1.34 cluster:
   ```bash
   kind create cluster --config kind-config.yaml --name upgrade-demo
   ```

## Application Deployment (Run on AWS EC2 Host)

1. Build the container image:
   ```bash
   docker build -t amitabhdevops/k8s-demo-app:v1.0.0 .
   ```

2. Load the image into the Kind cluster (recommended for local demo):
   ```bash
   kind load docker-image amitabhdevops/k8s-demo-app:v1.0.0 --name upgrade-demo
   ```

3. Deploy the application:
   ```bash
   kubectl apply -f k8s/manifests.yaml
   ```

4. Access the dashboard:
   Navigate to `http://<EC2-Public-IP>` in your browser. Ensure Port 80 is open in your Security Group.

---

## The Upgrade Process (v1.34.0 to v1.35.0)

Because Kind runs Kubernetes nodes inside Docker containers, the upgrade involves managing the host's kubectl and the internal components within each container node.

### Phase 1: Control Plane Upgrade

**Step 1: Drain the node (Run on EC2 Host)**
```bash
kubectl drain upgrade-demo-control-plane --ignore-daemonsets
```

**Step 2: Enter the node container (Run on EC2 Host)**
```bash
docker exec -it upgrade-demo-control-plane bash
```

**Step 3: Upgrade components (Run INSIDE Control Plane Container)**
```bash
# Configure v1.35 repository
apt update && apt install -y curl gnupg
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt update

# Upgrade kubeadm
apt-mark unhold kubeadm
apt install -y kubeadm=1.35.0-1.1
apt-mark hold kubeadm

# Run the upgrade
kubeadm upgrade plan --ignore-preflight-errors=SystemVerification
kubeadm upgrade apply v1.35.0 --ignore-preflight-errors=SystemVerification

# Upgrade kubelet and kubectl
apt-mark unhold kubelet kubectl
apt install -y kubelet=1.35.0-1.1 kubectl=1.35.0-1.1
apt-mark hold kubelet kubectl
systemctl restart kubelet

# Exit the container
exit
```

**Step 4: Uncordon the node (Run on EC2 Host)**
```bash
kubectl uncordon upgrade-demo-control-plane
```

---

### Phase 2: Worker Node 01 Upgrade

**Step 1: Drain the node (Run on EC2 Host)**
```bash
kubectl drain upgrade-demo-worker --ignore-daemonsets
```

**Step 2: Enter the node container (Run on EC2 Host)**
```bash
docker exec -it upgrade-demo-worker bash
```

**Step 3: Upgrade components (Run INSIDE Worker Container)**
```bash
# Configure v1.35 repository
apt update && apt install -y curl gnupg
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt update

# Upgrade tools and configuration
apt-mark unhold kubeadm kubelet kubectl
apt install -y kubeadm=1.35.0-1.1 kubelet=1.35.0-1.1 kubectl=1.35.0-1.1
kubeadm upgrade node --ignore-preflight-errors=SystemVerification
apt-mark hold kubeadm kubelet kubectl
systemctl restart kubelet

# Exit the container
exit
```

**Step 4: Uncordon the node (Run on EC2 Host)**
```bash
kubectl uncordon upgrade-demo-worker
```

---

### Phase 3: Worker Node 02 Upgrade

**Step 1: Drain the node (Run on EC2 Host)**
```bash
kubectl drain upgrade-demo-worker2 --ignore-daemonsets
```

**Step 2: Enter the node container (Run on EC2 Host)**
```bash
docker exec -it upgrade-demo-worker2 bash
```

**Step 3: Upgrade components (Run INSIDE Worker Container)**
```bash
# Configure v1.35 repository
apt update && apt install -y curl gnupg
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt update

# Upgrade tools and configuration
apt-mark unhold kubeadm kubelet kubectl
apt install -y kubeadm=1.35.0-1.1 kubelet=1.35.0-1.1 kubectl=1.35.0-1.1
kubeadm upgrade node --ignore-preflight-errors=SystemVerification
apt-mark hold kubeadm kubelet kubectl
systemctl restart kubelet

# Exit the container
exit
```

**Step 4: Uncordon the node (Run on EC2 Host)**
```bash
kubectl uncordon upgrade-demo-worker2
```

---

## Verification and Demonstration

Once the upgrade process is complete, follow these steps to verify success and demonstrate the changes visually.

### Command Line Verification
On your EC2 Host, check the cluster status:
```bash
kubectl get nodes -o wide
```
**Expected Output**: All nodes should report `STATUS: Ready` and `VERSION: v1.35.0`.

### Visual Demonstration
1. Open the **Cluster Monitor** dashboard.
2. During the worker upgrades, observe the pods being evicted and recreated on the remaining nodes.
3. Note the **Node Name** update in the dashboard for each pod.
4. Confirm that the application remained available (indicated by the **Live** pulse) throughout the entire rolling upgrade.

## Local Testing
To run the application locally without Kubernetes:
```bash
npm install
npm start
```
The dashboard will be available at http://localhost:3000.
