#!/bin/bash

CERT_MANAGER_VERSION=v1.2.0
VAULT_SECRETS_OPERATOR_VERSION=1.13.0

# Get CRDs for Cert Manager
wget https://github.com/jetstack/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.crds.yaml -O bootstrap/crds/cert-manager-crds.yaml

# Get CRDs for Vault Secrets Operator
wget https://raw.githubusercontent.com/ricoberger/vault-secrets-operator/${VAULT_SECRETS_OPERATOR_VERSION}/config/crd/bases/ricoberger.de_vaultsecrets.yaml -O bootstrap/crds/vault-secrets-operator-crds.yaml
