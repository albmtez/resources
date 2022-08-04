# HA Kubernetes cluster using k3s and kube-vip

Multiple nodes kubernetes cluster built using k3s. Kube-vip is used to asign the VIP (virtual IP) to one of the server nodes.

## Requirements

- kubectl (https://kubernetes.io/es/docs/tasks/tools/#kubectl)
- k3sup (https://github.com/alexellis/k3sup)

## Versions

Versions used in this guide:

- K3s: v1.24.3+k3s1
- Kube-vip: v0.5.0

## Infrastructure definition

- 3 server nodes:
    - cores: 2
    - memory: 4096MB
    - disk: 20GB
- 3 agent nodes:
    - cores: 2
    - memory: 4096MB
    - disk: 50GB
- VIP: 192.168.10.50

Feel free to adapt the configuration to your needs by modifying the file *infra/terraform/variables.tf*.

## Deploy infrastructure

### Terraform

Terraform recipes are contained in *infra/terraform* folder. The vms will be created in Proxmox.

Just launch the following commands from the folder:

```
terraform init
terraform plan
terraform apply
```

## Base configuration

Base configuration of the vms to install the cluster is made by applying an ansible playbook.

From the folder *infra/ansible* execute the following command:

```
ansible-playbook main.yaml
```

## ssh to the nodes

The user *kube* is created in every node. The ssh keys configured for this user to be able to connect via ssh are stored in *infra/common/ssh_key*.

You can connect to a node using:

```
ssh -i infra/common/ssh_key/id_rsa kube@<node_ip>
```

## Cluster creation

We'll use k3sup to install k3s remotely on each node and to join the nodes to the cluster.

By default, the commands shown in this section use a node taint in order to not schedule pods execution in the control plane nodes. If you want your nodes to be executed in server nodes remove this configuracion in *k3s-extra-args*.

### Using Klipper default k3s Load Balancer

Install k3sup in the first server node:

```
k3sup install \
    --host=192.168.10.51 \
    --user=kube \
    --k3s-version=v1.24.3+k3s1 \
    --local-path=config.k3s.yaml \
    --context k3s \
    --cluster \
    --tls-san 192.168.10.50 \
    --k3s-extra-args="--node-taint node-role.kubernetes.io/master=true:NoSchedule" \
    --ssh-key infra/common/ssh_key/id_rsa
```

kubectl config file will be generated with the name *config.k3s.yaml".

```
export KUBECONFIG=config.k3s.yaml
kubectl get nodes
```

We will install kube-vip in the first server node.

```
kubectl apply -f manifests/kube-vip-rbac.yaml
kubectl apply -f manifests/kube-vip-taint.yaml
```

Kube-vip is now installed and we should be able to ping de VIP (*ping 192.168.10.50*).

Let's add the other two server nodes:

```
k3sup join \
    --host=192.168.10.52 \
    --server-user=kube \
    --server-host=192.168.10.50 \
    --user=kube \
    --server \
    --k3s-extra-args="--node-taint node-role.kubernetes.io/master=true:NoSchedule" \
    --ssh-key infra/common/ssh_key/id_rsa
k3sup join \
    --host=192.168.10.53 \
    --server-user=kube \
    --server-host=192.168.10.50 \
    --user=kube \
    --server \
    --k3s-extra-args="--node-taint node-role.kubernetes.io/master=true:NoSchedule" \
    --ssh-key infra/common/ssh_key/id_rsa
```

*Note that we are using the VIP as the server host ip address to join the rest of the nodes.*

We have now a cluster with 3 server nodes. Let's add the 3 agent nodes:

```
k3sup join \
    --host=192.168.10.54 \
    --server-user=kube \
    --server-host=192.168.10.50 \
    --user=kube \
    --ssh-key infra/common/ssh_key/id_rsa
k3sup join \
    --host=192.168.10.55 \
    --server-user=kube \
    --server-host=192.168.10.50 \
    --user=kube \
    --ssh-key infra/common/ssh_key/id_rsa
k3sup join \
    --host=192.168.10.56 \
    --server-user=kube \
    --server-host=192.168.10.50 \
    --user=kube \
    --ssh-key infra/common/ssh_key/id_rsa
```

The cluster is ready!

We can check it creating a simple deployment and an ingress:

```
kubectl apply -f manifests/demo-ingress.yaml
```

Repeat the following curl to see a different pod responding on every request:

```
curl http://192.168.10.50/demo
```

### Using MetalLB

TODO

## Extra: Manifests generation

### Kube-vip

The RBAC manifest file can be downloaded directly from the kube-vip site:

```
curl -s https://kube-vip.io/manifests/rbac.yaml
```

This correspond to the file *manifests/kube-vip-rbac.yaml*.

In order to deploy kube-vip as a DaemonSet we will use the docker image to generate the manifest file configured to our cluster:

```
# export cluster specific configuration
export VIP=192.168.10.50
export INTERFACE=eth0

# fetch image
docker pull docker.io/plndr/kube-vip:latest

# create alias
alias kube-vip='docker run --rm docker.io/plndr/kube-vip:latest'

# generate manifest
kube-vip manifest daemonset \
    --arp \
    --interface $INTERFACE \
    --address $VIP \
    --controlplane \
    --leaderElection \
    --taint \
    --services \
    --inCluster
```
*taint* option is used because we want the kube-vip pods been executed only in server nodes.
