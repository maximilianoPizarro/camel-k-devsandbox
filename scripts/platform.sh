#!/bin/bash
set -euo pipefail

if ! oc whoami >/dev/null 2>&1; then
  echo "oc no esta autenticado. En el workspace de Dev Spaces la sesion ya viene iniciada."
  exit 1
fi

NS="$(oc project -q)"
echo "Preparando IntegrationPlatform camel-k en ${NS}"

# The integration pod pulls the kit by its registry URL. OpenShift only
# injects the namespace dockercfg automatically for ImageStream references,
# so the platform must name a secret that exists in this project.
SECRET="$(oc get sa default -o jsonpath='{.imagePullSecrets[0].name}' 2>/dev/null || true)"
if [[ -z "$SECRET" ]]; then
  echo "La ServiceAccount default no tiene imagePullSecrets."
  exit 1
fi

# profile OpenShift: the route trait (not ingress) creates the Route.
# routine: the build runs in the operator. A builder pod cannot update
# builds/status in this sandbox, because that permission is not delegable.
# S2I publishes an ImageStream in this project. Without this platform the
# operator publishes the kit in camel-k-operator and the pull fails.
oc apply -f - <<EOF
apiVersion: camel.apache.org/v1
kind: IntegrationPlatform
metadata:
  name: camel-k
  labels:
    app.kubernetes.io/part-of: camel-k-workshop
    app.kubernetes.io/name: camel-k
spec:
  profile: OpenShift
  build:
    publishStrategy: S2I
    timeout: 20m
    registry:
      address: image-registry.openshift-image-registry.svc:5000
      secret: ${SECRET}
      insecure: true
    buildConfiguration:
      strategy: routine
EOF

PHASE=""
for _ in $(seq 1 30); do
  PHASE="$(oc get integrationplatform camel-k -o jsonpath='{.status.phase}' 2>/dev/null || true)"
  if [[ "$PHASE" == "Ready" ]]; then
    break
  fi
  sleep 2
done

if [[ "$PHASE" != "Ready" ]]; then
  echo "IntegrationPlatform camel-k no quedo Ready (phase=${PHASE})."
  oc describe integrationplatform camel-k || true
  exit 1
fi

# The catalog CR in the sandbox can be older than the runtime that actually
# builds (Camel 4.22). ai-tool and mcp-server are not in that CR, so the
# dependencies trait rejects camel:ai-tool. Register the Quarkus artifacts.
CATALOG="$(oc get camelcatalog -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep quarkus | head -1 || true)"
if [[ -n "$CATALOG" ]]; then
  oc patch "camelcatalog/${CATALOG}" --type merge -p '{"spec":{"artifacts":{"camel-quarkus-ai-tool":{"artifactId":"camel-quarkus-ai-tool","groupId":"org.apache.camel.quarkus","schemes":[{"consumer":{},"http":false,"id":"ai-tool","passive":false,"producer":{}}]},"camel-quarkus-mcp-server":{"artifactId":"camel-quarkus-mcp-server","groupId":"org.apache.camel.quarkus","schemes":[{"consumer":{},"http":false,"id":"mcp-server","passive":false,"producer":{}}]}}}}'
  echo "Catalogo ${CATALOG}: agregados ai-tool y mcp-server."
fi

echo "IntegrationPlatform camel-k Ready. Build routine, publish S2I, pull secret ${SECRET}."
