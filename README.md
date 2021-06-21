<img src="docs/img/kubernetes-icon-color.png" align="left" width="144px" height="144px"/>

### My Kubernetes cluster running at home :sailboat:
_... automated management with Flux & updated by RenovateBot_ :robot:

<br/>
<br/>


## Warning!
This repo is still under heavy development and some things might not work as expected. You have been warned!

## Automation
We use a few different tools to automate as much as possible of the setup and maintenance of the cluster.

* Ansible is used to setup the High Availability aspects of the cluster as well as k3s.
* Flux syncs the cluster with the git repo containing all configuration.
* Renovatebot keeps the configuration up to date.

## High Availability
We use Keepalived and HAProxy on each of our server nodes. Keepalived passes around a Virtual IP (VIP) between the active nodes. So if one node is offline the VIP is passed on to one of the other nodes.

HAProxy keeps track of which control plane is up and running and load balances the requests between those.

So a request is made to the VIP and the HAProxy instance running on the node that has the VIP takes the request and passes it on to one of the currently available control planes. This makes it possible to have a server node up and running but without having the control plane running. This might be handy when doing some maintenance on a node.

## k3s
We use [k3s](https://www.k3s.io) to setup a lightweight Kubernetes cluster. K3s is installed using Ansible.

## Storage
We use a combination of Rook-Ceph and NFS for storage. Rook-Ceph is used to setup a Ceph cluster on the server nodes. NFS is used to mount the NFS share from our NAS to get access to, mainly media files.

[Troubleshooting & info](docs/rook-ceph.md)
