#!/bin/sh
set -ex

## Alternative to Vault-Agent: Get Vault token via K8S Service
# curl -s -k --request POST https://vault.vault.svc:8200/v1/auth/kubernetes/login --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt --data "{\"jwt\": \"$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)\", \"role\": \"default\"}" | jq -r ".auth.client_token" > /var/secrets/auth.token

sed "s/__ROLE__/$VAULT_KUBERNETES_ROLE/g" /etc/vault-agent-config.hcl > /tmp/vault-agent-config.hcl

# Requires VAULT_ADDR
# Get Vault Token via K8S Service Account (renew done by consul)
vault agent -config /tmp/vault-agent-config.hcl

# Start consule-template which starts and monitors the pgbouncer process
exec consul-template \
    -config=/etc/consul-template-config.hcl \
    -vault-addr=$VAULT_ADDR
