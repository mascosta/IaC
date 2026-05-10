# Unified Kubernetes Lab (Debian 12 + K8s 1.35)

Este projeto provisiona um cluster Kubernetes moderno usando **Debian 12 (Bookworm)**, **containerd** como runtime e **Kubernetes 1.35**.

## Pré-requisitos

1.  Vagrant instalado.
2.  VirtualBox instalado.
3.  Ajustar o `BRIDGE_INTERFACE` e `GATEWAY_IP` no `Vagrantfile` para refletir a sua rede local.

## Como usar

### 1. Provisionar as máquinas

```bash
vagrant up
```

### 2. Inicializar o Control Plane (CP)

Acesse a máquina control plane:
```bash
vagrant ssh k8s-cp
```

Inicialize o cluster usando o **IP da rede interna** (`10.255.255.10`) para a comunicação do control plane:
```bash
sudo kubeadm init --apiserver-advertise-address=10.255.255.10 --control-plane-endpoint=k8s-cp --upload-certs --token-ttl=0
```

Configure o `kubectl` para o seu usuário:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 3. Instalar o CNI

Nesse laboratório que será construído, será adotada a instalação através da CLI, que usa o [HELM](https://helm.sh/) em background para a tarefa. Seguem os comandos para instalação da CLI:

```bash
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
```
Com a CLI instalada, agora é necessário instalar o *CNI* no cluster:

```bash
cilium install --version=$(curl -s https://raw.githubusercontent.com/cilium/cilium/refs/heads/main/stable.txt)
```
### 4. Adicionar o Worker (WK)

Ao final do `kubeadm init`, você recebeu um comando `kubeadm join`. Copie-o.

Acesse o worker:
```bash
vagrant ssh k8s-wk-1
```

Execute o comando de join (com `sudo`):
```bash
sudo kubeadm join 10.255.255.10:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

### 5. Verificar o Cluster

No control plane:
```bash
kubectl get nodes
```

### 6. Instalar o cert-manager e metrics-server

#### cert-manager
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.20.2/cert-manager.yaml
```

#### metrics-server (TLS Seguro)
Para instalar o metrics-server sem a necessidade da flag `--kubelet-insecure-tls`:

1. Instale o metrics-server:
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

2. Habilite o TLS Bootstrap no ConfigMap do kubelet:
```bash
kubectl edit cm kubelet-config -n kube-system
# Adicione: serverTLSBootstrap: true
```

3. Propague a configuração e reinicie o serviço em **cada nó** (CP e Workers):
```bash
sudo kubeadm upgrade node phase kubelet-config
sudo systemctl restart kubelet
```

4. Aprove as solicitações de certificado (CSR) no Control Plane:
```bash
kubectl get csr
kubectl certificate approve <NOME_DO_CSR>
```

### 7. Instalação do NGINX Gateway Fabric (Kubernetes API Gateway)

O NGINX Gateway Fabric é a implementação moderna para roteamento de tráfego, substituindo o Ingress tradicional.

#### 1. Instalar os CRDs do Gateway API (Standard)
Este passo é obrigatório e deve ser executado antes do controlador:
```bash
kubectl kustomize "https://github.com/nginx/nginx-gateway-fabric/config/crd/gateway-api/standard?ref=v2.6.0" | kubectl apply -f -
```

#### 2. Instalar o NGINX Gateway Fabric
Instalação configurada para usar `NodePort` no cluster:
```bash
kubectl apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v2.6.0/deploy/nodeport/deploy.yaml
```

#### 3. Ajustar Política de Tráfego Externo
Para permitir acesso por qualquer IP do cluster (CP ou Workers), alteramos a política de tráfego:
```bash
kubectl patch nginxproxy nginx-gateway-proxy-config -n nginx-gateway --type='merge' -p '{"spec":{"kubernetes":{"service":{"externalTrafficPolicy":"Cluster"}}}}'
```

### 8. Configuração de DNS Local

Para acessar as aplicações pelo domínio, adicione ao seu arquivo `/etc/hosts` (no host físico):

```text
192.168.18.134 sistemas.k8s.local dev.k8s.local
```

## Estrutura de Arquivos

*   `Vagrantfile`: Configuração das VMs.
*   `scripts/common.sh`: Provisionamento base (containerd, kubeadm, kubectl, kubelet).
