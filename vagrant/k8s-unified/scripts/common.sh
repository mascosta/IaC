#!/bin/bash
set -e

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION_ID=$VERSION_ID
else
    echo "Cannot detect OS"
    exit 1
fi

HOSTNAME=$(hostname)
echo ">>> Detected OS: $OS on $HOSTNAME"

# echo ">>> Configuring SSH for Root Access..."
# # Enable Root Login and Password Auth (for lab convenience)
# sudo sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
# sudo systemctl restart ssh

# # Create .ssh directory for root
# sudo mkdir -p /root/.ssh
# sudo chmod 700 /root/.ssh

# # Generate key only on CP
# if [[ "$HOSTNAME" == "k8s-cp" ]]; then
#     if [ ! -f /root/.ssh/id_ed25519 ]; then
#         sudo ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519
#     fi
#     # Share the public key via /vagrant (shared folder)
#     sudo cp /root/.ssh/id_ed25519.pub /vagrant/id_root_cp.pub
# fi

# # All nodes wait a bit for the key (in case of parallel boot) and import it
# # Using a simple loop to wait up to 10 seconds if needed
# for i in {1..10}; do
#     if [ -f /vagrant/id_root_cp.pub ]; then
#         cat /vagrant/id_root_cp.pub | sudo tee -a /root/.ssh/authorized_keys > /dev/null
#         # Remove duplicates
#         sudo sort -u /root/.ssh/authorized_keys -o /root/.ssh/authorized_keys
#         sudo chmod 600 /root/.ssh/authorized_keys
#         sudo chown root:root /root/.ssh/authorized_keys
#         break
#     fi
#     sleep 1
# done

# # Disable Strict Host Key Checking for root convenience
# cat <<EOF | sudo tee /root/.ssh/config
# Host *
#     StrictHostKeyChecking no
#     UserKnownHostsFile /dev/null
# EOF
# sudo chmod 600 /root/.ssh/config

echo ">>> Preparing System..."
# Disable Swap
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# Load Kernel Modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

if [[ "$OS" == "debian" || "$OS" == "ubuntu" ]]; then
    echo ">>> Installing Dependencies (Debian-based)..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg gpg vim git

    echo ">>> Installing Containerd (CRI)..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $VERSION_CODENAME stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y containerd.io

    echo ">>> Installing Kubernetes v1.35..."
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl

elif [[ "$OS" == "ol" || "$OS" == "rhel" || "$OS" == "centos" ]]; then
    echo ">>> Installing Dependencies (RPM-based)..."
    sudo dnf install -y yum-utils device-mapper-persistent-data lvm2 vim net-tools

    echo ">>> Installing Containerd (CRI)..."
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo dnf install -y containerd.io
    
    # Disable Firewalld and SELinux (common for K8s on RPM)
    sudo systemctl disable --now firewalld || true
    sudo setenforce 0 || true
    sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
echo ">>> Installing Kubernetes v1.35..."
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.35/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.35/rpm/repodata/repomd.xml.key
EOF

sudo dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
fi

# Post-install configuration for Containerd
echo ">>> Configuring Containerd..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

# Simple replacement for SystemdCgroup
sudo sed -i 's,SystemdCgroup = false,SystemdCgroup = true,g' /etc/containerd/config.toml

sudo systemctl enable --now containerd
sudo systemctl restart containerd

sudo systemctl enable --now kubelet

sudo echo "source <(kubectl completion bash)" >> /root/.bashrc

sudo echo "source <(kubeadm completion bash)" >> /root/.bashrc 

echo ">>> Done! Node ready for 'kubeadm init' or 'kubeadm join'."
