#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CAMEL_VERSION="4.22.0"
LOCAL_PORT="8081"
JAVA_VERSION="17"
JVM_ARGS="-Xmx1024m"
export PATH="${HOME}/.jbang/bin:${PATH}"

usage() {
  cat <<'EOF'
Uso: bash scripts/local.sh <comando>

Comandos:
  install   Instala JBang y el Camel CLI 4.22.0
  hello     Corre labs/01-hello en el workspace
  http      Corre labs/02-http en 8081 y hace curl a /hello
  kafka     Sube el broker del lab y corre orders.camel.yaml
  granite   Corre ask.camel.yaml contra OpenShift AI
  mcp       Corre mcp.camel.yaml (Quarkus) y prueba /mcp y /ask
  stop      Detiene el proceso Camel JBang del workspace

En Dev Spaces: Terminal -> Run Task... y elegi Local — ...
EOF
}

need_oc() {
  if ! oc whoami >/dev/null 2>&1; then
    echo "oc no esta autenticado. En el workspace de Dev Spaces la sesion ya viene iniciada."
    exit 1
  fi
}

ensure_camel() {
  if ! command -v camel >/dev/null 2>&1; then
    echo "No esta el Camel CLI. Corré primero: Terminal -> Run Task... -> Local — Instalar Camel JBang"
    exit 1
  fi
}

camel_version_ok() {
  command -v camel >/dev/null 2>&1 || return 1
  local out
  out="$(camel version 2>/dev/null || true)"
  [[ "$out" == *"${CAMEL_VERSION}"* ]]
}

stop_local() {
  if ! command -v camel >/dev/null 2>&1; then
    echo "Camel CLI no instalado; no hay proceso local que detener."
    return 0
  fi
  if ! camel ps 2>/dev/null | grep -Eq 'Running|Starting'; then
    echo "No hay integraciones Camel JBang corriendo."
    return 0
  fi
  echo "Deteniendo Camel JBang..."
  camel stop --kill 2>/dev/null || camel stop 2>/dev/null || true
  sleep 1
}

clear_cluster_lab() {
  need_oc
  bash "$ROOT/scripts/down.sh"
}

wait_http() {
  local url="$1"
  local seconds="${2:-120}"
  local i
  for i in $(seq 1 "$seconds"); do
    if curl -fsS --max-time 5 "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  echo "No respondio ${url}"
  camel ps || true
  camel log --tail=80 2>/dev/null || true
  return 1
}

run_common_args() {
  CAMEL_COMMON=(
    --java-version="${JAVA_VERSION}"
    --jvm-args="${JVM_ARGS}"
  )
}

cmd_install() {
  if camel_version_ok; then
    echo "Camel CLI ${CAMEL_VERSION} ya esta instalado."
    camel version
    return 0
  fi

  if ! command -v jbang >/dev/null 2>&1; then
    echo "Instalando JBang en ${HOME}/.jbang ..."
    curl -Ls https://sh.jbang.dev | bash -s - app setup
    export PATH="${HOME}/.jbang/bin:${PATH}"
  fi

  if ! command -v jbang >/dev/null 2>&1; then
    echo "JBang no quedo en el PATH. Revisa ${HOME}/.jbang/bin"
    exit 1
  fi

  echo "Instalando Camel CLI ${CAMEL_VERSION}..."
  jbang app install --force --fresh \
    -Dcamel.jbang.version="${CAMEL_VERSION}" \
    -Dcamel-kamelets.version="${CAMEL_VERSION}" \
    camel@apache/camel

  export PATH="${HOME}/.jbang/bin:${PATH}"
  camel version
  echo
  echo "Listo. Segui con Local — Hello u otra tarea Local."
}

cmd_hello() {
  ensure_camel
  stop_local
  clear_cluster_lab
  run_common_args
  echo "Corriendo labs/01-hello/hello.camel.yaml (Ctrl+C o Local — Detener para parar)."
  exec camel run labs/01-hello/hello.camel.yaml "${CAMEL_COMMON[@]}"
}

cmd_http() {
  ensure_camel
  stop_local
  clear_cluster_lab
  run_common_args
  echo "Corriendo labs/02-http/hello.camel.yaml en el puerto ${LOCAL_PORT}..."
  camel run labs/02-http/hello.camel.yaml \
    "${CAMEL_COMMON[@]}" \
    --port="${LOCAL_PORT}" \
    --background \
    --background-wait=120s
  wait_http "http://127.0.0.1:${LOCAL_PORT}/hello" 90
  echo
  echo "-- GET /hello --"
  curl -fsS "http://127.0.0.1:${LOCAL_PORT}/hello"
  echo
  echo
  echo "Sigue corriendo en background. Para pararlo: Local — Detener."
  camel ps || true
}

cmd_kafka() {
  ensure_camel
  need_oc
  stop_local
  clear_cluster_lab
  echo "Aplicando el broker Kafka del lab..."
  oc apply -f "$ROOT/labs/03-kafka/kafka.yaml"
  oc rollout status deployment/kafka --timeout=300s
  run_common_args
  echo "Corriendo labs/03-kafka/orders.camel.yaml (Ctrl+C o Local — Detener para parar)."
  echo "Esperá el log: pedido recibido pedido A-100"
  exec camel run labs/03-kafka/orders.camel.yaml "${CAMEL_COMMON[@]}"
}

cmd_granite() {
  ensure_camel
  need_oc
  stop_local
  clear_cluster_lab
  export LLM_TOKEN
  LLM_TOKEN="$(oc whoami -t)"
  run_common_args
  echo "Corriendo labs/04-granite contra el predictor de OpenShift AI..."
  camel run labs/04-granite/ask.camel.yaml platform/SandboxTrust.java \
    "${CAMEL_COMMON[@]}" \
    --port="${LOCAL_PORT}" \
    --background \
    --background-wait=180s
  wait_http "http://127.0.0.1:${LOCAL_PORT}/ask" 180
  echo
  echo "-- GET /ask --"
  curl -fsS --max-time 180 "http://127.0.0.1:${LOCAL_PORT}/ask"
  echo
  echo
  echo "Sigue corriendo en background. Para pararlo: Local — Detener."
  camel ps || true
}

cmd_mcp() {
  ensure_camel
  need_oc
  stop_local
  clear_cluster_lab
  export LLM_TOKEN
  LLM_TOKEN="$(oc whoami -t)"
  run_common_args
  echo "Corriendo labs/05-mcp con runtime Quarkus (el tag MCP se fija al construir)..."
  camel run labs/05-mcp/mcp.camel.yaml platform/SandboxTrust.java \
    "${CAMEL_COMMON[@]}" \
    --runtime=quarkus \
    --dep=org.apache.camel.quarkus:camel-quarkus-ai-tool:3.39.0 \
    --dep=org.apache.camel.quarkus:camel-quarkus-mcp-server:3.39.0 \
    --property=quarkus.camel.mcp-server.tags=orders \
    --property=quarkus.mcp.server.server-info.name=camel-k-workshop \
    --property=quarkus.mcp.server.http.root-path=/mcp \
    --port="${LOCAL_PORT}" \
    --background \
    --background-wait=10m

  wait_http "http://127.0.0.1:${LOCAL_PORT}/ask?orderId=A-100" 300 || true

  echo
  HDR="$(mktemp)"
  echo "-- initialize --"
  curl -fsS --max-time 60 -D "$HDR" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"workshop","version":"0.1.0"}}}' \
    "http://127.0.0.1:${LOCAL_PORT}/mcp"
  echo
  SID="$(awk 'tolower($1)=="mcp-session-id:" {print $2}' "$HDR" | tr -d '\r')"
  rm -f "$HDR"
  SESSION=()
  if [[ -n "$SID" ]]; then
    echo "Mcp-Session-Id: ${SID}"
    SESSION=(-H "Mcp-Session-Id: ${SID}")
  fi
  echo "-- notifications/initialized --"
  curl -sS --max-time 60 -o /dev/null -w "HTTP %{http_code}\n" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    "${SESSION[@]}" \
    -d '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
    "http://127.0.0.1:${LOCAL_PORT}/mcp" || true
  echo "-- tools/list --"
  curl -fsS --max-time 60 \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    "${SESSION[@]}" \
    -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
    "http://127.0.0.1:${LOCAL_PORT}/mcp"
  echo
  echo "-- tools/call --"
  curl -fsS --max-time 60 \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    "${SESSION[@]}" \
    -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"order-status","arguments":{"orderId":"A-100"}}}' \
    "http://127.0.0.1:${LOCAL_PORT}/mcp"
  echo
  echo "-- /ask --"
  curl -fsS --max-time 180 "http://127.0.0.1:${LOCAL_PORT}/ask?orderId=B-200"
  echo
  echo
  echo "Sigue corriendo en background. Para pararlo: Local — Detener."
  camel ps || true
}

cmd_stop() {
  stop_local
  echo "Proceso local detenido. El Paso 0 del operador no mata Camel JBang."
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

case "$1" in
  install) cmd_install ;;
  hello) cmd_hello ;;
  http) cmd_http ;;
  kafka) cmd_kafka ;;
  granite) cmd_granite ;;
  mcp) cmd_mcp ;;
  stop) cmd_stop ;;
  *)
    usage
    exit 1
    ;;
esac
