<img src="docs/img/kubernetes-icon-color.png" align="left" width="144px" height="144px"/>

### My Kubernetes cluster running at home :sailboat:
_... automated management with Flux & updated by RenovateBot_ :robot:

<br/>
<br/>
<br />
<br />

## we
So this is my Kubernetes cluster that is running at home serving both home automation, media and other services.

## Automation
We use a few different tools to automate as much as possible of the setup and maintenance of the cluster.

* Ansible is used to setup the High Availability aspects of the cluster as well as k3s.
* Flux syncs the cluster with the git repo containing all configuration.
* Renovatebot keeps the configuration up to date.
* Github Actions to both keep a few manifests up to date and also to validate the configuration.

## High Availability
We use Keepalived and HAProxy on each of our server nodes. Keepalived passes around a Virtual IP (VIP) between the active nodes. So if one node is offline the VIP is passed on to one of the other nodes.

HAProxy keeps track of which control planes is up and running and load balances the requests between those.

So a request is made to the VIP and the HAProxy instance running on the node that has the VIP takes the request and passes it on to one of the currently available control planes. This makes it possible to have a server node up and running but without having the control plane running. This might be handy when doing some maintenance on a node.

## k3s
We use [k3s](https://www.k3s.io) to setup a lightweight Kubernetes cluster. K3s is installed using Ansible.

## Storage
We use a combination of Rook-Ceph and NFS for storage. Rook-Ceph is used to setup a Ceph cluster on the server nodes. NFS is used to mount the NFS share from our NAS to get access to, mainly media files.

[Troubleshooting & info](docs/rook-ceph.md)

## Bootstrap
I wish it was as easy as running a `flux bootstrap` command to get everything running, but it isn't. The main problem is Rook-Ceph since it takes up to 15 minutes for the cluster to get up and running. So this is what I did the last time:

### Install OS
TODO

### Install k3s
TODO

### Bootstrap cluster
First, make sure that the disks that Rook Ceph is supposed to use are nuked.

```shell
$ ansible-playbook playbooks/nuke-rook-ceph.yaml
```

After that each of the nodes that has newly nuked disks needs to be rebooted. For some reason this is needed or Rook Ceph wont be able to create new OSDs.

Next, comment the line with `- rook-ceph` in `./cluster/core/kustomization.yaml` so it looks like:

```yaml
---

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespaces
  - tigera-operator
  - metallb-system
  - kube-system
  #- rook-ceph
  - cert-manager
  - system-upgrade
```

Also edit `./cluster/apps/kustomization.yaml`: Theoretically we could also suspend the reconsiliation off `apps` using flux but by doing it this way we can prepare before we actually start bootstraping the cluster.

```yaml
---

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - flux-system
  - kube-system
  - monitoring
  #- network
  #- home-automation
  #- media
  - system-upgrade
```

Create the flux namespace:

```shell
$ kubectl create namespace flux-system
```

Add SOPS secret to cluster to Flux can decrypt the encrypted secrets:

```shell
$ gpg --list-secret-keys REPLACE@WITH_CORRECT_MAIL.COM

$ gpg --export-secret-keys \
  --armor RANDOM_STRING_FROM_ABOVE_COMMAND |
kubectl create secret generic sops-gpg \
  --namespace=flux-system \
  --from-file=sops.asc=/dev/stdin
```

Next up, bootstrap with flux:

```shell
$ flux bootstrap github \
  --owner=ahinko \
  --repository=k8s-cluster \
  --path=cluster/bootstrap/ \
  --personal \
  --branch=main
```

Time to get Rook Ceph up and running:

```shell
$ kubectl apply -f ./cluster/core/rook-ceph/common/common.yaml
$ kubectl apply -f ./cluster/core/rook-ceph/operator/operator.yaml
$ kubectl apply -f ./cluster/core/rook-ceph/cluster/cluster.yaml
$ kubectl apply -f ./cluster/core/rook-ceph/dashboard/dashboard.yaml
```

Time to WAIT! Go get something to drink. When you can access the dashboard using `rook.domain.com` the cluster is done. If we don't wait for this then Rook-Ceph fails for some reason.

```shell
$ kubectl apply -f ./cluster/core/rook-ceph/filesystem/filesystem.yaml
$ kubectl apply -f ./cluster/core/rook-ceph/storage-class/storage-class.yaml
```

These steps are only needed if backups should be restored:

* Apply all the PVCs that's needed.
* Restore backups using the manifests in the `./tools/restores-backups` folder.

The final step is to uncomment all the lines we commented above in `./cluster/core/kustomization.yaml` and `./cluster/apps/kustomization.yaml`.
