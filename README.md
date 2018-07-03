# Purpose
This document provides instructions on bootstraping a 3 node kubernetes cluster with a single master on vagrant based VM environments. The repository also contains a vagrant file that can be used to run the vms.

## Prerequisites
- Vagrant
- Virtualbox or any other virtualization provider
- jq

## Vagrant file
In the default state, the vagrant file will create 3 ubuntu/xenial64 based virtual machines. Here are the details:

| Name        | IP           | Role  |
| ------------- |:-------------:| -----:|
| controller-0      | 192.168.99.10 | Controller |
| worker-0      | 192.168.99.20      |   Worker |
| worker-1 | 192.168.99.21     |    Worker |


## Install the tools
Run the following commands on all the VMs. If you are using [tmux]('https://github.com/tmux/tmux/wiki') or [iterm2]('https://www.iterm2.com/') you can use the sync pane feature to get this done on all machines at once.

```bash
sudo su -

#Update and install kubernetes tools
apt-get update
apt-get install -y kubelet kubeadm kubectl

#Add vagrant user to the docker group
sudo usermod -a -G docker vagrant

#log out and back in
sudo su -
su vagrant
```

## Initialize the Master
Run the following command On controller-0. The `--pod-network-cidr=10.244.0.0/16` argument is only required if you want to use flannel as the network addon. If you want to use some other network see the kubeadm documentation at (https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#tabs-pod-install-0)

```bash
sudo kubeadm init --apiserver-advertise-address=192.168.99.10 --pod-network-cidr=10.244.0.0/16
```

The `--apiserver-advertise-address` flag is required to advertise the private ip of the controller as the communication address. This is required as vagrant creates multiple network interfaces.

Follow the instructions printed by the init command as the vagrant user to make kubectl work for the vagrant user.

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Apply the flannel network addon. Required if you are using the flannel network addon.
```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
``` 

Copy the join command as printed on the console. You will need to run this command on the worker nodes. 

## Join Worker Nodes:
Make sure the tools have been installed

Modify the `/etc/defaults/kubelet` file like so

```bash
cat /etc/default/kubelet 
KUBELET_EXTRA_ARGS=--node-ip=<worker private ip>
```
the `--node-ip` parameter is used to make sure that the kubelet is listening on the private ip address.

Restart the kubelet service
```bash
sudo systemctl restart kubelet
```

Run the join command

```bash
sudo kubeadm join --token <token> <master-ip>:<master-port> --discovery-token-ca-cert-hash sha256:<hash>
```


## Control the cluster from the host machine
```bash
scp root@<master ip>:/etc/kubernetes/admin.conf .
kubectl --kubeconfig ./admin.conf get nodes
```

## Verification

Note: Requires [jq](https://stedolan.github.io/jq/)
```bash
kubectl cluster-info

#Should print the worker nodes
kubectl get nodes

#Should print the private ip address of the worker nodes
kubectl get node worker-0 -o json|jq  '.status.addresses[0].address'
kubectl get node worker-1 -o json|jq  '.status.addresses[0].address'
```

For more information and troubleshooting tips see the [kubeadm](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/) documentation.