#!/bin/bash

set -e

until [ "$(kubectl get po test-application -o=jsonpath='{.status.containerStatuses[0].state.terminated.reason}')" == "Completed" ];
do
  echo "Waiting for test pod to be completed. Current status is " $(kubectl get po test-application -o=jsonpath='{.status.containerStatuses[0].state}')
  echo "Logs: "
  kubectl logs --ignore-errors -c main-application test-application
  kubectl logs --ignore-errors -c pgbouncer-vault-sidecar test-application
  sleep 10s
done

echo "Test container completed"

kubectl logs test-application -c main-application
