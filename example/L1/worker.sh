#!/bin/bash


# Step 1: Turn off swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Step 2: Config bridge
modprobe overlay
modprobe br_netfilter

echo """
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
""" > /etc/sysctl.d/kubernetes.conf
sysctl --system


# Step 3: Install containerd

apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

apt update
apt install -y containerd.io

# Config containerd
containerd config default | tee /etc/containerd/config.toml >/dev/null 2>&1
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd


# Step 3: Add kubernetes repo

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
apt-add-repository -y "deb http://apt.kubernetes.io/ kubernetes-xenial main"

# jammy is work only for ubuntu 22

# Step 4: Install kubernetes components

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

sudo apt update

sudo apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl


# Step 5: Config access cluster as root
echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> /root/.bashrc
source /root/.bashrc

export KUBECONFIG=/etc/kubernetes/admin.conf

# Step 6: Config crictl for debugging:
echo """
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
""" | tee /etc/crictl.yaml

# Step 7: Join cluster
# Copy join cluster command here.
#
# It should start with kubeadm join ...


