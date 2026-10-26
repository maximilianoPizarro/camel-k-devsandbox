#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

usage() {
  cat <<'EOF'
Uso: bash scripts/up.sh <lab>

Labs:
  01-hello
  02-http
  03-kafka
  04-granite
  05-mcp

El lab anterior se borra antes de aplicar este.
En Dev Spaces: Terminal -> Run Task... y elegi Outer — …
EOF
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

LAB="$1"
case "$LAB" in
  01-hello) INTEGRATION=hello ;;
  02-http) INTEGRATION=http-hello ;;
  03-kafka) INTEGRATION=orders ;;
  04-granite) INTEGRATION=granite ;;
  05-mcp) INTEGRATION=mcp ;;
  *)
    usage
    exit 1
    ;;
esac

if ! oc whoami >/dev/null 2>&1; then
  echo "oc no esta autenticado. En el workspace de Dev Spaces la sesion ya viene iniciada."
  exit 1
fi

if command -v python3 >/dev/null 2>&1; then
  PYTHON=python3
else
  PYTHON=python
fi

echo "Proyecto activo: $(oc project -q)"
bash "$ROOT/scripts/platform.sh"
bash "$ROOT/scripts/down.sh"
"$PYTHON" "$ROOT/scripts/sync.py"

if [[ "$LAB" == "03-kafka" ]]; then
  oc apply -f "$ROOT/labs/03-kafka/kafka.yaml"
  oc rollout status deployment/kafka --timeout=300s
fi

if [[ "$LAB" == "04-granite" || "$LAB" == "05-mcp" ]]; then
  oc apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: sandbox-llm-token
  labels:
    app.kubernetes.io/part-of: camel-k-workshop
    workshop.camel-k/lab: ${LAB}
type: Opaque
stringData:
  token: "$(oc whoami -t)"
EOF
fi

oc apply -f "$ROOT/labs/$LAB/integration.yaml"

echo "Esperando a que integration/${INTEGRATION} quede Ready (el primer build puede tardar varios minutos)..."
if ! oc wait --for=condition=Ready "integration/${INTEGRATION}" --timeout=1200s; then
  echo "La Integration no llego a Ready."
  oc describe "integration/${INTEGRATION}" || true
  oc get pods -l "camel.apache.org/integration=${INTEGRATION}" -o wide || true
  exit 1
fi

echo
echo "== Integration =="
oc get "integration/${INTEGRATION}" -o wide
echo
echo "== Status =="
oc get "integration/${INTEGRATION}" -o jsonpath='phase={.status.phase}{"\n"}image={.status.image}{"\n"}' || true
oc describe "integration/${INTEGRATION}" | awk 'BEGIN{p=0} /^Status:/{p=1} /^Events:/{p=0} p' | head -n 40 || true

echo
echo "Kaoto: abri labs/${LAB}/*.camel.yaml"
echo "Consola: barra de estado Dev Spaces -> Open OpenShift Console"
echo "         Perspectiva Developer -> Topology -> deployment ${INTEGRATION}"

if [[ "$LAB" == "01-hello" || "$LAB" == "03-kafka" ]]; then
  echo
  echo "Esperando las primeras lineas de log..."
  sleep 12
  oc logs -l "camel.apache.org/integration=${INTEGRATION}" --tail=40 || true
fi

if [[ "$LAB" == "02-http" || "$LAB" == "04-granite" || "$LAB" == "05-mcp" ]]; then
  echo
  echo "Esperando la Route..."
  for _ in $(seq 1 30); do
    HOST="$(oc get "route/${INTEGRATION}" -o jsonpath='{.spec.host}' 2>/dev/null || true)"
    if [[ -n "$HOST" ]]; then
      break
    fi
    sleep 2
  done
  if [[ -z "${HOST:-}" ]]; then
    echo "No aparecio route/${INTEGRATION}. Revisa oc get route."
    oc get route || true
    exit 1
  fi
  echo "Route: https://${HOST}"
fi

if [[ "$LAB" == "02-http" ]]; then
  echo
  curl -kfsS "https://${HOST}/hello"
  echo
fi

if [[ "$LAB" == "04-granite" ]]; then
  echo
  echo "-- GET /ask (pregunta por defecto: Content-Based Router) --"
  curl -kfsS --max-time 180 "https://${HOST}/ask"
  echo
  echo
  echo "Probá otras preguntas:"
  echo "  curl -k \"https://${HOST}/ask?q=Escribe+una+ruta+Apache+Camel+en+YAML+que+lea+de+Kafka+y+escriba+en+un+log\""
  echo "  curl -k \"https://${HOST}/ask?q=Que+hace+el+componente+platform-http+de+Apache+Camel\""
fi

if [[ "$LAB" == "05-mcp" ]]; then
  echo
  HDR="$(mktemp)"
  echo "-- initialize --"
  curl -kfsS --max-time 60 -D "$HDR" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"workshop","version":"0.1.0"}}}' \
    "https://${HOST}/mcp"
  echo
  SID="$(awk 'tolower($1)=="mcp-session-id:" {print $2}' "$HDR" | tr -d '\r')"
  rm -f "$HDR"
  SESSION=()
  if [[ -n "$SID" ]]; then
    echo "Mcp-Session-Id: ${SID}"
    SESSION=(-H "Mcp-Session-Id: ${SID}")
  fi
  echo "-- notifications/initialized --"
  curl -ksS --max-time 60 -o /dev/null -w "HTTP %{http_code}\n" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    "${SESSION[@]}" \
    -d '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
    "https://${HOST}/mcp" || true
  echo "-- tools/list --"
  curl -kfsS --max-time 60 \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    "${SESSION[@]}" \
    -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
    "https://${HOST}/mcp"
  echo
  echo "-- tools/call --"
  curl -kfsS --max-time 60 \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    "${SESSION[@]}" \
    -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"order-status","arguments":{"orderId":"A-100"}}}' \
    "https://${HOST}/mcp"
  echo
  echo "-- /ask --"
  curl -kfsS --max-time 180 "https://${HOST}/ask?orderId=B-200"
  echo
fi

echo
echo "Lab ${LAB} activo. La tarea Outer siguiente lo reemplaza."
echo "Para apagarlo: Terminal -> Run Task... -> Outer — Clean"
