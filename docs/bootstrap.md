# Bootstrap the cluster

## Bootstrap process

The bootstrap process can be divided in to the following steps:

- [ ] Run Ansible to setup the server nodes with Keepalived and HAProxy. Also adds authentication and URL for the local Docker registry.
- [ ] Run k3sup to setup server nodes and agent nodes.
- [ ] Run the `bootstrap.sh` script to setup the infrastructure inside the cluster.
  - [ ] Set up Calico
  - [ ] Set up Rook & Ceph
  - [ ] Install needed CRDs for Cert Manager, Vault Secrets Operator, System Upgrade Controller
  - [ ] Create all the needed PVCs
  - [ ] Restore backups to the created PVCs
  - [ ] Bootstrap Flux
  - [ ] Restore backup of Consul to the Consul backend

## Step by step

### Restore Consul snapshot
Download the backup you want to restore and place it in the `bootstrap/consul` folder and name the file `snapshot.tgz`

### Restore data to volumes
To restore backups for Home Assistant, NodeRed, Zwave2mqtt, Zigbee2mqtt and more you need to update the corresponding **job manifest** stored in the `tools/restore-backups` folder. You need to update the `RESTORE_FILE` environment variable to match the filename of the backup you want to use. The provided filename will be used when the restore job downloads the file from the Minio instance. This is the same location where the **backup cronjob** places the created archives.

### Export needed variables

First we need the `GITHUB_TOKEN` that Flux can use for communicating with the Github repo. [Read more about how to generate access tokens](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line).

```shell
$ export GITHUB_USER=ahinko
$ export GITHUB_TOKEN=*****
```

We also need the `VAULT_TOKEN` to be able to set up the Vault-secret-operator.

**Please note that this will be an issue when setting up a new vault from scratch.**

```shell
$ export VAULT_TOKEN=*****
```
