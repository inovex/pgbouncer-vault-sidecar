#!/bin/bash

if [ "$1" != "run" ]; then
    echo "This script requires a configured Minikube cluster and will remove pods. Pass 'run' as an argument to continue."
    exit 30
fi

set -ex

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR

kubectl -n kube-system wait --timeout=2m --for=condition=Available deployment/coredns
eval $(minikube -p minikube docker-env)
docker build -t pgbouncer-vault ../build

kubectl delete po --grace-period=1 vault || true
kubectl delete po --grace-period=1 postgres || true
kubectl delete po --grace-period=1 test-application || true

kubectl apply -f manifests/vault.yaml
kubectl apply -f manifests/app-sa.yaml
kubectl apply -f manifests/postgres.yaml

kubectl wait --for=condition=Ready pod/vault
kubectl wait --for=condition=Ready pod/postgres

kubectl exec vault -- vault auth enable kubernetes

kubectl exec vault -- vault write auth/kubernetes/config \
                            kubernetes_host=https://kubernetes \
                            kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
                            token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token

kubectl exec vault -- vault write auth/kubernetes/role/database-access \
                            bound_service_account_names=test-application \
                            bound_service_account_namespaces=default \
                            policies=test-database \
                            ttl=1h

cat policy.hcl | kubectl exec vault -i -- vault policy write test-database - 

kubectl exec vault -- vault secrets enable database

until kubectl exec vault -- nslookup postgres.default.svc.cluster.local.
do
  echo "Wait until Postgres service resolves to pod"
  sleep 3
done

kubectl exec vault -- vault write database/config/my-database \
    plugin_name=postgresql-database-plugin \
    allowed_roles="my-role" \
    connection_url="postgresql://postgres:supersecret@postgres.default.svc.cluster.local.:5432/?sslmode=disable"

kubectl exec vault -- vault write database/roles/my-role \
    db_name=my-database \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"

kubectl apply -f manifests/app.yaml