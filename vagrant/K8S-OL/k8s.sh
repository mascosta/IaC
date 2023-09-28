#!/bin/bash

echo "Adicionando repositorios do kubernetes"


cat << EOF >> /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF


echo "Configurando arquivo kubernetes-cri"

cat << EOF > /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

echo "Configurando modulos do containerd"

cat << EOF >> /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

echo "Recarregando configurações"

sysctl --system &&  sysctl -p

echo "Criando e configurando arquivo config.toml do containerd"

mkdir -p /etc/containerd && \
containerd config default > /etc/containerd/config.toml && \
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

echo "Habilitando serviço do containerd"

systemctl enable --now containerd