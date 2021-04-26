#!/bin/bash

wget https://docs.projectcalico.org/manifests/tigera-operator.yaml -O cluster/tigera-operator/operator/tigera-operator-crds.yaml

cat <<EOT >> cluster/tigera-operator/operator/tigera-operator-crds.yaml
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: kubernetes.io/hostname
                    operator: In
                    values:
                      - helios
                      - zeus
                      - iris
EOT
