#!/bin/bash
sudo swapoff -a && \
# Need to check in which line is your swap parameter in /etc/fstab, in this case I supose it is in line 13.
sudo cp /home/vagrant/k8s.conf /etc/modules-load.d/k8s.conf && \
sudo cp /home/vagrant/daemon.json /etc/docker/daemon.json && \
sudo mkdir -p /etc/systemd/system/docker.service.d && \
sudo systemctl daemon-reload && \
sudo systemctl restart docker && sudo apt-get update && \
sudo apt-get install -y apt-transport-https gnupg2 && \
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && \
sudo echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list && \
sudo apt-get update && sudo apt-get install -y kubelet=1.23.17* kubeadm=1.23.17* kubectl=1.23.17* && \
sudo echo "source <(kubectl completion bash)" >> ~/.bashrc && \
sudo echo "source <(kubeadm completion bash)" >> ~/.bashrc #&& \
