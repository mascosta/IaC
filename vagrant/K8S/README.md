# IaC
## Provisionamento de um cluster kubernetes via VAGRANT

Conteúdo gerado a partir do guia da LINUXtips (Descomplicando Kubernetes).

## Introdução.

Esse guia é voltado para quem teve dificuldade de montar o ambiente "do zero" ou, simplesmente, não quer perder tempo provisionando máquinas virtuais uma a uma. 

Para o laboratório é necessário usar a ferramenta chamada **vagrant**, através do [link](https://www.vagrantup.com/downloads).

Importante salientar que não é toda máquina que aguenta esse tipo de "laboratório" então, use com cautela!

![](https://giffiles.alphacoders.com/207/207963.gif)

## Instruções de uso.

## 1 - Clonar o repositório.

```bash
git clone https://github.com/mascosta/IaC.git
```

## 2 - Alterar o arquivo **Vagrantfile** nas variáveis de interface de rede e endereço do gateway da **SUA** rede.

## 3 - Executar o comando abaixo para provisionar o ambiente:

```bash
vagrant up
```
## 4 - Com o ambiente já rodando, agora resta acessar a máquina.

```bash
vagrant ssh ${NomeDaVM}
```
## 5 - ~~Como descrito no livro [Descomplicando Kubernetes](https://livro.descomplicandokubernetes.com.br/pt/day_one/descomplicando_kubernetes.html) basta seguir os passos a partir da sessão **Inicialização do cluster** e pronto, o ambiente para estudos já está ok. :)~~

>    Nota: Aparentemente o link do livro mudou e, no acesso pelo que vi do [atual](https://github.com/badtuxx/DescomplicandoKubernetes) não encontrei a abordagem da inicialização do cluster, então, segue versão inicializando e usando o calico como CNI! :)

## 5 - Inicialização do cluster

### 5.1 - Acesse a VM master.

```bash
vagrant ssh k8s-master
```

### 5.2 - Veja qual o endereço de IP da interface da VM.


```bash
ip address show | grep "inet "
```

### 5.3 - Baseado nesse endereço, execute o comando de inicialização do cluster.


```bash
kubeadm init --token-ttl 0 --service-cidr=10.255.255.0/24 --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=<IP_da_Interface>
```
> Nota:  Os parâmetros ```--service-cidr``` e ```--pod-network-cidr``` são opcionais!

### 5.4 - Após a inicalização, você deverá ver um retorno similar ao abaixo:

```bash
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.100.230:6443 --token EITATOKENZAO \
	--discovery-token-ca-cert-hash sha256:EITACHAVEZONA

```

- 5.4.1 - Esse trecho é usado para que você copie as informações e configurações do cluster para usa pasta de usuário, permitido ao ```kubectl``` entender onde vai trabalhar.

```bash
To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

- 5.4.2 - Já o comando abaixo, trata-se do que será executado nos nós workers para ingresso no cluster.

```bash
kubeadm join 192.168.100.230:6443 --token EITATOKENZAO \
    --discovery-token-ca-cert-hash sha256:EITACHAVEZONA
# Cuidado que as vezes aparece um ponto quando copia e cola... :/
```

### 5.5 - Após adição dos nós, ao executar o comando ```kubectl get nodes``` será observado que eles ficação como *NotReady*.

```bash
root@k8s-master:/kubernetes# kubectl get nodes
NAME         STATUS   ROLES                  AGE    VERSION
k8s-1        NotReady    <none>                 124m   v1.23.17
k8s-2        NotReady    <none>                 124m   v1.23.17
k8s-master   NotReady    control-plane,master   125m   v1.23.17

```
- Para que ele mude para **Ready** é necessária a instalação do *CNI*(Container Network Interface) onde, para esse guia, será instalado o [CALICO 3.25](https://docs.tigera.io/calico/3.25/getting-started/kubernetes/self-managed-onprem/onpremises)

```bash
#Instalação do OPERATOR (Opcional)
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/tigera-operator.yaml
#Download do manifest
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/calico.yaml -O
#Instalação do manifest
kubectl create -f calico.yaml
```

### 5.6 - Pra finalizar, será instalado o Metrics-Server, que permite monitoramento dos nós e pods do cluster.

```bash
#Download do manifest
wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

```bash
#Editar o arquivo para ignorar a checagem TLS
vim components.yaml
```

```yaml
#Adicionar --kubelet-insecure-tls abaixo do parâmetro --metric-resolution, como mostrado abaixo:
spec:
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        - --kubelet-insecure-tls
```

### 6 - Validando o funcionamento:

```bash
root@k8s-master:/kubernetes# kubectl get nodes
NAME         STATUS   ROLES                  AGE    VERSION
k8s-1        Ready    <none>                 141m   v1.23.17
k8s-2        Ready    <none>                 141m   v1.23.17
k8s-master   Ready    control-plane,master   142m   v1.23.17
root@k8s-master:/kubernetes# kubectl top nodes
NAME         CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
k8s-1        349m         17%    1092Mi          57%       
k8s-2        381m         19%    1094Mi          57%       
k8s-master   332m         16%    1381Mi          72% 
```


## Agora é correr pro abraço! :D

![](https://chemnitzer.linux-tage.de/2017/static/img/box/tuxel.gif)
