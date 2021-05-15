#!/bin/bash

CERT_MANAGER_VERSION=v1.3.1
VAULT_SECRETS_OPERATOR_VERSION=1.14.3

# Get CRDs for Cert Manager
wget https://github.com/jetstack/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.crds.yaml -O cluster/cert-manager/cert-manager/crds.yaml

# Get CRDs for Vault Secrets Operator
wget https://raw.githubusercontent.com/ricoberger/vault-secrets-operator/${VAULT_SECRETS_OPERATOR_VERSION}/config/crd/bases/ricoberger.de_vaultsecrets.yaml -O cluster/vault/secrets-operator/crds.yaml
