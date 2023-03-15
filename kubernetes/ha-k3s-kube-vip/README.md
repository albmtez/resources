# HA Kubernetes cluster using k3s and kube-vip

Multiple nodes kubernetes cluster built using k3s. Kube-vip is used to asign the VIP (virtual IP) to one of the server nodes.

## Requirements

- kubectl (https://kubernetes.io/es/docs/tasks/tools/#kubectl)
- k3sup (https://github.com/alexellis/k3sup)

## Versions

Versions used in this guide:

- K3s: v1.25.7+k3s1
- Kube-vip: v0.5.0
- MetalLB: v0.13.4

## Infrastructure definition

- 3 server nodes:
    - cores: 2
    - memory: 4096MB
    - disk: 20GB
- 3 agent nodes:
    - cores: 2
    - memory: 4096MB
    - disk: 50GB
- VIP: 192.168.10.100

Feel free to adapt the configuration to your needs by modifying the file *infra/terraform/variables.tf*.

## Deploy infrastructure

### Terraform

Terraform recipes are contained in *infra/terraform* directory. The vms will be created in Proxmox.

Just launch the following commands from the folder:

```
terraform init
terraform plan
terraform apply
```

### Multipass

You can create the vms using Multipass executing the script in *infra/multipass* directory:

```
./create_vms.sh
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

By default, the commands shown in this section use a node taint in order to not schedule pods execution in the control plane nodes. If you want your nodes to be executed in server nodes remove this configuration in *k3s-extra-args*.

### Using Klipper default k3s Load Balancer

Install k3sup in the first server node:

```
k3sup install \
    --host=192.168.10.101 \
    --user=kube \
    --k3s-version=v1.25.7+k3s1 \
    --local-path=config.k3s.yaml \
    --context k3s \
    --cluster \
    --tls-san 192.168.10.100 \
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
kubectl apply -f manifests/kube-vip.yaml
```

Kube-vip is now installed and we should be able to ping de VIP (*ping 192.168.10.100*).

Let's add the other two server nodes:

```
k3sup join \
    --host=192.168.10.102 \
    --server-user=kube \
    --k3s-version=v1.25.7+k3s1 \
    --server-host=192.168.10.100 \
    --user=kube \
    --server \
    --k3s-extra-args="--node-taint node-role.kubernetes.io/master=true:NoSchedule" \
    --ssh-key infra/common/ssh_key/id_rsa
k3sup join \
    --host=192.168.10.103 \
    --server-user=kube \
    --k3s-version=v1.25.7+k3s1 \
    --server-host=192.168.10.100 \
    --user=kube \
    --server \
    --k3s-extra-args="--node-taint node-role.kubernetes.io/master=true:NoSchedule" \
    --ssh-key infra/common/ssh_key/id_rsa
```

*Note that we are using the VIP as the server host ip address to join the rest of the nodes.*

We have now a cluster with 3 server nodes. Let's add the 3 agent nodes:

```
k3sup join \
    --host=192.168.10.104 \
    --server-user=kube \
    --k3s-version=v1.25.7+k3s1 \
    --server-host=192.168.10.100 \
    --user=kube \
    --ssh-key infra/common/ssh_key/id_rsa
k3sup join \
    --host=192.168.10.105 \
    --server-user=kube \
    --k3s-version=v1.25.7+k3s1 \
    --server-host=192.168.10.100 \
    --user=kube \
    --ssh-key infra/common/ssh_key/id_rsa
k3sup join \
    --host=192.168.10.106 \
    --server-user=kube \
    --k3s-version=v1.25.7+k3s1 \
    --server-host=192.168.10.100 \
    --user=kube \
    --ssh-key infra/common/ssh_key/id_rsa
```

The cluster is ready!

We can check it creating a simple deployment and an ingress:

```
kubectl apply -f manifests/demo-ingress.yaml
```

Open the following url in your browser: http://test.192.168.10.100.sslip.io

### Using MetalLB

We will create a cluster disabling the load balancer service and installing MetalLB instead.

Install k3sup in the first server node:

```
k3sup install \
    --host=192.168.10.101 \
    --user=kube \
    --k3s-version=v1.24.3+k3s1 \
    --local-path=config.k3s.yaml \
    --context k3s \
    --cluster \
    --tls-san 192.168.10.100 \
    --k3s-extra-args="--disable servicelb --node-taint node-role.kubernetes.io/master=true:NoSchedule" \
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
kubectl apply -f manifests/kube-vip.yaml
```

Kube-vip is now installed and we should be able to ping de VIP (*ping 192.168.10.50*).

Let's add the other two server nodes:

```
k3sup join \
    --host=192.168.10.102 \
    --server-user=kube \
    --server-host=192.168.10.100 \
    --user=kube \
    --server \
    --k3s-extra-args="--disable servicelb --node-taint node-role.kubernetes.io/master=true:NoSchedule" \
    --ssh-key infra/common/ssh_key/id_rsa
k3sup join \
    --host=192.168.10.103 \
    --server-user=kube \
    --server-host=192.168.10.100 \
    --user=kube \
    --server \
    --k3s-extra-args="--disable servicelb --node-taint node-role.kubernetes.io/master=true:NoSchedule" \
    --ssh-key infra/common/ssh_key/id_rsa
```

*Note that we are using the VIP as the server host ip address to join the rest of the nodes.*

We have now a cluster with 3 server nodes. Let's add the 3 agent nodes:

```
k3sup join \
    --host=192.168.10.104 \
    --server-user=kube \
    --server-host=192.168.10.100 \
    --user=kube \
    --ssh-key infra/common/ssh_key/id_rsa
k3sup join \
    --host=192.168.10.105 \
    --server-user=kube \
    --server-host=192.168.10.100 \
    --user=kube \
    --ssh-key infra/common/ssh_key/id_rsa
k3sup join \
    --host=192.168.10.106 \
    --server-user=kube \
    --server-host=192.168.10.100 \
    --user=kube \
    --ssh-key infra/common/ssh_key/id_rsa
```

All server and agent nodes are now ready. We can install and configure MetalLB:

```
# Install MetalLB
kubectl apply -f manifests/metallb-native.yaml

# Create the ip address pool
kubectl apply -f manifests/metallb-ipaddresspool.yaml

# Create de L2 advertisement
kubectl apply -f manifests/metallb-l2advertisement.yaml
```

Now, we should see an external ip address assigned to the Traefik LB:

```
kubectl get svc -n kube-system
NAME             TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                      AGE
kube-dns         ClusterIP      10.43.0.10      <none>         53/UDP,53/TCP,9153/TCP       35m
metrics-server   ClusterIP      10.43.203.199   <none>         443/TCP                      35m
traefik          LoadBalancer   10.43.139.109   192.168.1.80   80:30877/TCP,443:30612/TCP   10m
```

We can now test it creating a simple deployment and an ingress:

```
kubectl apply -f manifests/demo-ingress.yaml
```

Open the following url in your browser: http://test.192.168.10.100.sslip.io

Another test exposing the service through the Load Balancer:

```
# Create de deployment
kubectl create deploy demo2 --image monachus/rancher-demo --port 8080 --replicas=3

# Expose
kubectl expose deploy demo2 --type=LoadBalancer --port=80 --target-port=8080

# Check the external ip assigned
kubectl get svc | grep demo2
demo2        LoadBalancer   10.43.55.115   192.168.10.81   80:32222/TCP   96s
```

Open the url in your web browser: http://192.168.10.81

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
export VIP=192.168.10.100
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

### MetalLB

The manifest to install MetalLB can be downloaded directly from metallb site:

```
wget https://raw.githubusercontent.com/metallb/metallb/v0.13.4/config/manifests/metallb-native.yaml
```

Layer 2 configuration manifests can be copied from the docs: https://metallb.universe.tf/configuration/#layer-2-configuration

```
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.240-192.168.1.250
```

```
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
```
