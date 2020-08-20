#!/bin/bash

minikube start \
  --extra-config 'apiserver.service-account-signing-key-file=/var/lib/minikube/certs/sa.key' \
  --extra-config 'apiserver.service-account-issuer=kubernetes/serviceaccount' \
  --extra-config 'apiserver.service-account-api-audiences=api'

