#!/bin/bash

set -e

until [ "$(kubectl get po test-application -o=jsonpath='{.status.containerStatuses[0].state.terminated.reason}')" == "Completed" ];
do
  echo "Waiting for test pod to be completed. Current status is " $(kubectl get po test-application -o=jsonpath='{.status.containerStatuses[0].state}')
  sleep 10s
done

echo "Test container completed"

 kubectl logs test-application -c main-application