# CodeReady Containers (CRC) on a remote server

Easily create a VM, deploy an OpenShift instance and configure it to be accessed remotely.

## Create your OCP instance

### Pull secret

A pull secret file `pull-secret.txt` is needed to be able to download the images needed to deploy the OpenShift instance with CRC.

Go to the url https://cloud.redhat.com/openshift/create/local and download your own `Pull Secret`. Replace the existing `pull-secret.txt` file in this repo with your own file.

### Using vagrant

#### Pre-requisites

The following Vagrant plugins are needed (`vagran plugin install <plugin_name>`):

- vagrant-disksize
- vagrant-libvirt
- vagrant-mutate
- vagrant-reload

If you're using Virtualbox in Linux, edit the file `/etc/vbox/networks.conf` (create this file if it doesn't exist), adding the following line:

```
* 10.0.0.0/24
```

This configuration is needed to be able to use the network `10.0.0.0/24` to assign the IP address to the VM.

#### Create your VM

If libvirt is your preference just run:

```
$ vagrant up --provider libvirt
```

A new VM will be created using Centos 8 as OS. CRC will then be used to configure and deploy you OpenShift instance.

If you prefer using Virtualbox as the hypervisor of your choice, simply run:

```
$ vagrant up --provider virtualbox
```

## Accessing the OCP cluster

Access the OpenShift Container Platform cluster running in the CRC instance by using the OpenShift Container Platform web console or OpenShift CLI (`oc`).

### Setup your client machine

The client machine is the remote laptop from which the user will connect to OpenShift. As CRC is using some internal DNS names and normally sets them in the local hosts file, these need to be added on the client machine. As IP, use the IP address of your server that runs CRC.

Add the following line to your `/etc/hosts` file:

```
10.0.0.20 api.crc.testing console-openshift-console.apps-crc.testing default-route-openshift-image-registry.apps-crc.testing oauth-openshift.apps-crc.testing
```

*Remember adding a new entry for each route or app deployed in OpenShift.*

### Accessing the OCP web console

The server is accessible via web console at:
  https://console-openshift-console.apps-crc.testing

Two users are available by default, a **regular user**:

    Username: developer
    Password: developer

and an **admin user**:

    Username: kubeadmin
    Password: you can retrieve the password executing the command `crc console --credentials`

### Accessing the OCP cluster with the OCP CLI

Login as the developer (or kubeadmin) user.

```
$ oc login -u developer https://api.crc.testing:6443
```

You can now use `oc` to interact with your OpenShift Container Platform cluster. For example, to verify that the OpenShift Container Platform cluster Operators are available, log in as the `kubeadmin` user and run the following command:

```
$ oc config use-context crc-admin
$ oc whoami
kubeadmin
$ oc get co
```

## Manage your OCP instance

You can manage your OCP instance from within your VM created by vagrant. Connect to your VM:

```
vagrant ssh
```

Check your OCP instance status:

```
[vagrant@crc ~]$ crc status
CRC VM:          Stopped
OpenShift:       Stopped (v4.12.0)
RAM Usage:       0B of 0B
Disk Usage:      0B of 0B (Inside the CRC VM)
Cache Usage:     15.75GB
Cache Directory: /home/vagrant/.crc/cache
```

Start your OCP instance (stopped by default when the VM is restarted):

```
[vagrant@crc ~]$ crc start
```

Get console credentials:

```
[vagrant@crc ~]$ crc console --credentials
```
