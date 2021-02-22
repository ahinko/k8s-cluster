#!/bin/bash

RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

echo "#######################################"
echo "# Welcome to the k3s bootstrap script #"
echo "#######################################"
echo -e ""

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo -e "${RED}Existing. Missing GITHUB_TOKEN, did you forget to export it?${NOCOLOR}"
  exit;
fi

if [[ -z "$VAULT_TOKEN" ]]; then
  echo -e "${RED}Existing. Missing VAULT_TOKEN, did you forget to export it?${NOCOLOR}"
  exit;
fi

echo "The boostrap process expects a running cluster. Check the readme for more information about how to do that."
echo -n "Press 'y' to continue, any other key to cancel: "
read answer

if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo -e "${GREEN}Ok, lets continue.${NOCOLOR}"
else
    echo -e "${RED}User cancelled the bootstrap script. Exiting.${NOCOLOR}"
    exit
fi

echo -e "\n${BOLD}Set up Calico${NORMAL}"
kubectl apply -f cluster/tigera-operator/namespace.yaml
kubectl apply -f cluster/tigera-operator/operator/tigera-operator.yaml
kubectl apply -f cluster/tigera-operator/resources/custom-resources.yaml

echo "Waiting for Calico to start."
echo -n "Press 'y' to continue, any other key to cancel: "
read answer

if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo -e "${GREEN}Calico up and running, lets continue.${NOCOLOR}"
else
    echo -e "${RED}User cancelled the bootstrap script. Exiting.${NOCOLOR}"
    exit
fi

echo -e "\n${BOLD}Setting up Rook Ceph${NORMAL}"
kubectl apply -f cluster/rook-ceph/crds/
kubectl apply -f cluster/rook-ceph/common/
kubectl apply -f cluster/rook-ceph/operator/

echo "Waiting for Rook Ceph operator to start."
echo -n "Press 'y' to continue, any other key to cancel: "
read answer

if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo -e "${GREEN}Rook Ceph Operator up and running, lets continue.${NOCOLOR}"
else
    echo -e "${RED}User cancelled the bootstrap script. Exiting.${NOCOLOR}"
    exit
fi

kubectl apply -f cluster/rook-ceph/cluster/
kubectl apply -f cluster/rook-ceph/dashboard/

echo -e "\n${BOLD}Wait for Rook Ceph cluster to be created.${NORMAL}"
echo -n "Press 'y' to continue, any other key to cancel: "
read answer

if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo -e "${GREEN}Rook Ceph cluster up and running, lets continue.${NOCOLOR}"
else
    echo -e "${RED}User cancelled the bootstrap script. Exiting.${NOCOLOR}"
    exit
fi

echo "Creating filesystem and storage class"
kubectl apply -f cluster/rook-ceph/filesystem/
kubectl apply -f cluster/rook-ceph/storage-class/

echo -e "\n${BOLD}Deploying resources that needs to exist in the cluster before Flux can run.${NORMAL}"
kubectl apply -f bootstrap/crds/
kubectl apply -f cluster/system-upgrade/system-upgrade-controller.yaml

echo -e "\n${BOLD}Setting up PVCs.${NORMAL}"
kubectl apply -f cluster/home-automation/home-assistant/persistent-volume-claim.yaml
kubectl apply -f cluster/home-automation/node-red/persistent-volume-claim.yaml
kubectl apply -f cluster/home-automation/zigbee2mqtt/persistent-volume-claim.yaml
kubectl apply -f cluster/home-automation/zwave2mqtt/persistent-volume-claim.yaml

kubectl apply -f cluster/media/bazarr/persistent-volume-claim.yaml
kubectl apply -f cluster/media/lidarr/persistent-volume-claim.yaml
kubectl apply -f cluster/media/radarr/persistent-volume-claim.yaml
kubectl apply -f cluster/media/sabnzbd/persistent-volume-claim.yaml
kubectl apply -f cluster/media/sonarr/persistent-volume-claim.yaml
kubectl apply -f cluster/media/sonarr-uhd/persistent-volume-claim.yaml

echo -e "\n${BOLD}Restoring data to PVCs.${NORMAL}"
kubectl apply -f tools/restore-backups/home-assistant-job.yaml
kubectl apply -f tools/restore-backups/node-red-job.yaml
kubectl apply -f tools/restore-backups/zigbee2mqtt-job.yaml
kubectl apply -f tools/restore-backups/zwave2mqtt-job.yaml

kubectl apply -f tools/restore-backups/bazarr-job.yaml
kubectl apply -f tools/restore-backups/lidarr-job.yaml
kubectl apply -f tools/restore-backups/radarr-job.yaml
kubectl apply -f tools/restore-backups/sabnzbd-job.yaml
kubectl apply -f tools/restore-backups/sonarr-job.yaml
kubectl apply -f tools/restore-backups/sonarr-uhd-job.yaml

echo -e "\n${BOLD}Bootstrapping Flux.${NORMAL}"
flux bootstrap github \
  --owner=${GITHUB_USER} \
  --repository=k8s-cluster \
  --path=cluster/ \
  --personal \
  --branch=main

echo -e "\n${BOLD}Wait for Consul cluster to be created.${NORMAL}"
echo "- Also make sure there is a file named ${BOLD}snapshot.tgz${NORMAL} in the ${BOLD}bootstrap/consul${NORMAL} folder."
echo "- Dont forget to port forward consul to local host to be able to access the API."
echo "  Use: kubectl port-forward -n vault service/consul-consul-server 8500:8500"

echo -n "Press 'y' to continue, any other key to cancel: "
read answer

if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo -e "${GREEN}Consul cluster up and running, lets continue.${NOCOLOR}"
else
    echo -e "${RED}User cancelled the bootstrap script. Exiting.${NOCOLOR}"
    exit
fi

echo -e "\n${BOLD}Restoring Consul backup${NORMAL}"
tools/restore-backups/consul-restore.sh bootstrap/consul/snapshot.tgz
tools/bootstrap-auth-secrets-operator.sh
