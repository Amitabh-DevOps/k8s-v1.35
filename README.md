# Kubernetes Upgrade Demonstration: v1.34 to v1.35

This repository contains a sample Node.js application and the necessary infrastructure manifests to demonstrate a Kubernetes cluster upgrade from version 1.34 to 1.35. The application provides a real-time dashboard that displays pod telemetry, making it easy to visualize how workloads are managed during a rolling update.

## Project Components

### Application Layer
The application is a lightweight Node.js server built with Express. It provides a telemetry API that retrieves pod information directly from the Kubernetes environment using the Downward API.
- server.js: The backend server logic.
- public/: A modern frontend dashboard showing pod name, node name, namespace, and system metrics.

### Containerization
The project includes a multi-stage Dockerfile that produces a minimal runtime image.
- Dockerfile: Optimized for production-grade deployments.

### Kubernetes Manifests
Standard resource definitions for deploying the application and exposing it to external traffic.
- k8s/manifests.yaml: Includes a Deployment with three replicas and a LoadBalancer Service. It also configures the Downward API to inject environment variables.

### Cluster Setup and Automation
Tools to quickly provision a test environment on AWS EC2 or local machines.
- setup-k8s.sh: A shell script for Ubuntu-based systems that installs Docker, Kind, and Kubectl.
- kind-config.yaml: A Kind cluster configuration that initializes a three-node cluster (one control plane and two workers) at version 1.34.0.

## Usage Instructions

### Environment Preparation
1. Copy the setup script to your Ubuntu instance and execute it:

   ```bash
   chmod +x setup-k8s.sh
   ./setup-k8s.sh
   ```

2. Update Docker group:

   ```bash
   newgrp docker
   ```

3. Provision the Kind cluster:
   ```bash
   kind create cluster --config kind-config.yaml --name upgrade-demo
   ```

### Deployment
1. Build and push your container image:
   ```bash
   docker build -t your-registry/k8s-demo-app:v1.0.0 .
   docker push your-registry/k8s-demo-app:v1.0.0
   ```

2. Update the image field in k8s/manifests.yaml with your specific image tag.

3. Deploy the application:
   ```bash
   kubectl apply -f k8s/manifests.yaml
   ```

### Cluster Upgrade Process
To demonstrate the upgrade from version 1.34.0 to 1.35.0, follow these standard Kubernetes maintenance steps. This process simulates a professional `kubeadm` based upgrade.

#### 1. Plan the Upgrade
Check for the available versions and ensure the cluster is ready for the transition.
   ```bash
   kubeadm upgrade plan
   ```

#### 2. Upgrade the Control Plane Node
Apply the upgrade to the first control plane node.
   ```bash
   # Drain the node to move pods
   kubectl drain control-plane-node --ignore-daemonsets

   # Upgrade kubeadm component   
   sudo apt update
   sudo apt install -y kubeadm=1.35.0-1.1

   # Run the upgrade
   sudo kubeadm upgrade apply v1.35.0

   # Upgrade kubelet and kubectl
   sudo apt install -y kubelet=1.35.0-1.1 kubectl=1.35.0-1.1
   sudo systemctl daemon-reload
   sudo systemctl restart kubelet

   # Uncordon the node
   kubectl uncordon control-plane-node
   ```

#### 3. Upgrade Worker Nodes
Repeat these steps for each worker node in your cluster.
   ```bash
   # From the control plane:
   kubectl drain worker-node-01 --ignore-daemonsets

   # From the worker node:
   sudo apt update
   sudo apt install -y kubeadm=1.35.0-1.1
   sudo kubeadm upgrade node
   sudo apt install -y kubelet=1.35.0-1.1 kubectl=1.35.0-1.1
   sudo systemctl daemon-reload
   sudo systemctl restart kubelet

   # From the control plan e:
   kubectl uncordon worker-node-01
   ```

### Demonstration Guidance
Access the application dashboard by navigating to the **Public IP of your EC2 instance** in your web browser (ensure port 80 is open in your AWS Security Group).

As you drain nodes and upgrade components:
1. Observe the "Node Name" in the dashboard change as pods are rescheduled.
2. Monitor the "Live" pulse to ensure zero-downtime during the rolling process.
3. Verify the final versioning across all nodes once the process is complete.

## Local Development
To run the application locally for testing:
1. Install dependencies:
   npm install
2. Start the server:
   npm start
3. Access the dashboard at http://localhost:3000.
