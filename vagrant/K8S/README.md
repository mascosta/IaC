# IaC
## Provisionamento de um cluster kubernetes via VAGRANT

Conteúdo gerado a partir do guia da LINUXtips (Descomplicando Kubernetes).

## Introdução.

Esse guia é voltado para quem teve dificuldade de montar o ambiente "do zero" ou, simplesmente, não quer perder tempo provisionando máquinas virtuais uma a uma. 

Importante salientar que não é toda máquina que aguenta esse tipo de "laboratório" então, use com cautela!

![](https://giffiles.alphacoders.com/207/207963.gif)

## Instruções de uso.

### 1 - Clonar o repositório.

```bash
git clone https://github.com/mascosta/IaC.git
```

### 2 - Alterar o arquivo **Vagrantfile** nas variáveis de interface de rede e endereço do gateway da **SUA** rede.

### 3 - Executar o comando abaixo para provisionar o ambiente:

```bash
vagrant up
```
### 4 - Com o ambiente já rodando, agora resta acessar a máquina.

```bash
vagrant ssh ${NomeDaVM}
```
### 5 - Como descrito no livro [Descomplicando Kubernetes](https://livro.descomplicandokubernetes.com.br/pt/day_one/descomplicando_kubernetes.html) basta seguir os passos a partir da sessão **Inicialização do cluster** e pronto, o ambiente para estudos já está ok. :)

![image](https://user-images.githubusercontent.com/55152388/164872900-2f0f2365-4621-417b-a3f4-c3d9f88f5938.png)


## Agora é correr pro abraço! :D

![](https://chemnitzer.linux-tage.de/2017/static/img/box/tuxel.gif)
