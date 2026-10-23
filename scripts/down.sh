#!/bin/bash
set -euo pipefail

if ! oc whoami >/dev/null 2>&1; then
  echo "oc no esta autenticado. En el workspace de Dev Spaces la sesion ya viene iniciada."
  exit 1
fi

echo "Proyecto activo: $(oc project -q)"
echo "Borrando recursos con app.kubernetes.io/part-of=camel-k-workshop"

oc delete integration -l app.kubernetes.io/part-of=camel-k-workshop \
  --ignore-not-found=true --wait=true --timeout=180s
oc delete deployment,service,route,configmap,secret -l app.kubernetes.io/part-of=camel-k-workshop \
  --ignore-not-found=true --wait=true --timeout=180s

if oc get pods -l app.kubernetes.io/part-of=camel-k-workshop --no-headers 2>/dev/null | grep -q .; then
  oc wait --for=delete pod -l app.kubernetes.io/part-of=camel-k-workshop --timeout=180s || true
fi

echo "Labs del workshop apagados."
oc get resourcequota compute-deploy
