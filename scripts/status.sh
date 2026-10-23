#!/bin/bash
set -euo pipefail

if ! oc whoami >/dev/null 2>&1; then
  echo "oc no esta autenticado. En el workspace de Dev Spaces la sesion ya viene iniciada."
  exit 1
fi

echo "Usuario: $(oc whoami)"
echo "Proyecto activo: $(oc project -q)"
echo
echo "== Cuota de pods largos =="
oc get resourcequota compute-deploy
echo
echo "== Recursos del workshop =="
oc get integration,deployment,service,route,configmap,secret \
  -l app.kubernetes.io/part-of=camel-k-workshop 2>/dev/null || true
echo
echo "== Pods del proyecto =="
oc get pods -o wide
