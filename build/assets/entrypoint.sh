#!/bin/sh
set -ex

## Alternative to Vault-Agent: Get Vault token via K8S Service
# curl -s -k --request POST https://vault.vault.svc:8200/v1/auth/kubernetes/login --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt --data "{\"jwt\": \"$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)\", \"role\": \"default\"}" | jq -r ".auth.client_token" > /var/secrets/auth.token

sed "s/__ROLE__/$VAULT_KUBERNETES_ROLE/g" /etc/vault-agent-config.hcl > /tmp/vault-agent-config.hcl

echo Authenticating against Vault
# Requires VAULT_ADDR
# Get Vault Token via K8S Service Account (renew is done by consul)
#
# consul-template cannot authenticate to Vault via Kubernetes (only via Vault token). 
# However, Vault agent cannot be used as a process supervisor.
# So we need both.
# Vault agent exit once it has written the token to file.
vault agent -config /tmp/vault-agent-config.hcl

echo Successfully obtained Vault token
echo Starting consul-template

# Start consule-template which starts and monitors the pgbouncer process
exec consul-template \
    -config=/etc/consul-template-config.hcl \
    -vault-addr=$VAULT_ADDR
