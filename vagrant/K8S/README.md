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

[-Nota:-] Aparentemente o link do livro mudou e, no acesso pelo que vi do [atual](https://github.com/badtuxx/DescomplicandoKubernetes) não encontrei a abordagem da inicialização do cluster, então, segue versão inicializando e usando o calico como CNI! :)

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
[-Nota-]  Os parâmetros ```--service-cidr``` e ```--pod-network-cidr``` são opcionais!


![image](https://user-images.githubusercontent.com/55152388/164872900-2f0f2365-4621-417b-a3f4-c3d9f88f5938.png)


## Agora é correr pro abraço! :D

![](https://chemnitzer.linux-tage.de/2017/static/img/box/tuxel.gif)
