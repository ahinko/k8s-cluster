# Vault

We use Vault to store our secrets in the cluster. [Vault](https://www.vaultproject.io/) uses [Consul](https://www.consul.io) as storage backend and the final piece of the pussle is the [Vault Secrets Operator](https://github.com/ricoberger/vault-secrets-operator) that creates regular Kubernetes secrets from Vault secrets.

The [Vault Secrets Operator](https://github.com/ricoberger/vault-secrets-operator) also keeps the secrets in sync so if a secret is updated in [Vault](https://www.vaultproject.io/) the Kubernetes secret will also be updated automatically.

## Bootstrap

The bootstrap process is taken care of the `bootstrap.sh` script. Manual steps can be found below if needed.

## Unsealing locked Vaults

We have a simple bash script that run on different servers and each server has the key stored on its filesystem (`/root/.vault-key.json`). This IS NOT the most secure solution but for a Homelab its good enough for me. Also note that at least 3 of the servers having these keys would have to be compromised to be able to unseal the Vault.

We have a custom service set up that exposes sealed vault instances. See the `cluster/vault/vault/extra-standby-service.yaml` manifest. When the first Vault instance has been sealed the service will expose the next sealed instance.

```bash
#!/bin/bash

VAULT_HOST=192.168.*.*
VAULT_PORT=31102

STATUS=$(curl -s http://$VAULT_HOST:$VAULT_PORT/v1/sys/seal-status)

if [[ $STATUS == "" ]]; then
    echo "Could not get Vaults sealed status"
    exit 1
fi

if [[ $STATUS == *"sealed\":true"* ]]; then
    echo "Vault is sealed!"

    curl -s \
    --request PUT \
    --data @/root/.vault-key.json \
    http://$VAULT_HOST:$VAULT_PORT/v1/sys/unseal
fi
```

## Access Consul UI
The Consul UI is not accessible by default. We need to port forward to be able to access the UI:

```shell
$ kubectl port-forward -n vault service/consul-consul-server 8500:8500
```

Once the port is forwarded navigate to http://localhost:8500

## Restore Consul snapshot
Use the `tools/restore-backups/consul.sh` script in the tools folder. Port forward using the command above and copy the snapshot to the `tools` folder (or change the path in the script). Then run the script to restore the snapshot.

You still need to setup the Vault Secrets Operator (see below.)

## Initialize a new Vault
This is only needed if we want to start from scratch and don't want to restore a consul snapshot/backup (see above).

```shell
$ kubectl exec -n vault vault-0 -- vault operator init -key-shares=5 -key-threshold=3 -format=json > cluster-keys.json
```

### Get unseal keys and root token

Might need to install jq: `brew install jq`

```shell
$ cat cluster-keys.json | jq -r ".unseal_keys_b64[]"

$ cat cluster-keys.json | jq -r ".root_token"
```

### Unseal vaults

If we for some reason need to unseal the Vault manually this can be done with the following commands:

```shell
$ kubectl exec -n vault vault-0 -- vault operator unseal <unseal key>

$ kubectl exec -n vault vault-1 -- vault operator unseal <unseal key>
```
