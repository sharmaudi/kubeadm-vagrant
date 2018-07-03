#!/usr/bin/env bash

#apt update and install docker
apt-get update && apt-get install -y apt-transport-https curl docker.io

#Add kubernetes sources
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

#Update and install kubernetes tools
apt-get update
apt-get install -y kubelet kubeadm kubectl

#Add vagrant user to the docker group
sudo usermod -a -G docker vagrant

#log out and back in
sudo su -
su vagrant