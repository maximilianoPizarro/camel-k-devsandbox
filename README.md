[![Open](https://img.shields.io/static/v1?label=Open%20in&message=Developer%20Sandbox&logo=eclipseche&color=FDB940&labelColor=525C86)](https://workspaces.openshift.com/#https://github.com/maximilianoPizarro/camel-k-devsandbox/tree/master?storageType=ephemeral)

<p align="left">
<img src="https://img.shields.io/badge/redhat-CC0000?style=for-the-badge&logo=redhat&logoColor=white" alt="Red Hat">
<img src="https://img.shields.io/badge/OpenShift-EE0000?style=for-the-badge&logo=redhatopenshift&logoColor=white" alt="OpenShift">
<img src="https://img.shields.io/badge/Apache%20Camel-FFDD00?style=for-the-badge&logo=apachecamel&logoColor=black" alt="Apache Camel">
<img src="https://img.shields.io/badge/Apache%20Kafka-231F20?style=for-the-badge&logo=apachekafka&logoColor=white" alt="Apache Kafka">
</p>

# Camel K en Developer Sandbox

Workshop para recorrer Apache Camel K dentro de un workspace de [OpenShift Dev Spaces](https://docs.redhat.com/en/documentation/red_hat_openshift_dev_spaces/3.28/html/user_guide/assembly_getting-started_user_guide) en el mismo [Developer Sandbox](https://developers.redhat.com/developer-sandbox). Cada paso es una tarea del `devfile.yaml`. El paso siguiente borra el anterior, así en el proyecto queda un solo ejemplo vivo.

El operador Camel K ya está instalado en el sandbox y observa tu proyecto. Estos labs no instalan otro operador. En el sandbox de referencia el kit arranca con Camel 4.22.0 y Camel Quarkus 3.39.0 (Quarkus 3.39.1). Puede haber un CamelCatalog 3.15.3 en el proyecto; el build usa el runtime del IntegrationPlatform, no ese catálogo. Outer — Hello imprime la versión en el log del pod.

## Qué vas a dejar corriendo

| Lab | Tarea en Dev Spaces | Qué crea | Qué mirar |
| --- | --- | --- | --- |
| 0 | Outer — Clean | Borra lo etiquetado por el workshop | Topology vacío de estos labs |
| 1 | Outer — Hello | Integration `hello` | Log `hello Hola desde Camel K...` |
| 2 | Outer — HTTP | Integration `http-hello` y su Route | `GET /hello` |
| 3 | Outer — Kafka | Deployment `kafka` e Integration `orders` | Log `pedido recibido pedido A-100` |
| 4 | Outer — Granite | Integration `granite`, Secret del token y Route | Texto del modelo en `GET /ask` |
| 5 | Outer — MCP | Integration `mcp`, Secret del token y Route | `tools/list`, `tools/call` y `GET /ask` |

### Misma ruta, en el workspace (Camel JBang)

La primera tarea Inner que ejecutes instala JBang y el Camel CLI 4.22.0 automáticamente (las siguientes veces es instantáneo). El comando `camel run` aparece directo en el devfile para que lo copies a cualquier terminal. Desde una terminal manual: `source scripts/install-jbang.sh` y después el `camel run` que quieras.

| Tarea | Comando | Qué mirar |
| --- | --- | --- |
| Inner — Hello | `camel run labs/01-hello/hello.camel.yaml` | Log en la terminal |
| Inner — HTTP | `camel run labs/02-http/hello.camel.yaml --port=8081` | `curl http://127.0.0.1:8081/hello` desde otra terminal |
| Inner — Kafka | `oc apply` del broker + `camel run labs/03-kafka/orders.camel.yaml` | Log `pedido recibido pedido A-100` |
| Inner — Granite | `export LLM_TOKEN=$(oc whoami -t)` + `camel run labs/04-granite/ask.camel.yaml platform/SandboxTrust.java --port=8081` | `curl http://127.0.0.1:8081/ask` desde otra terminal |
| Inner — MCP | `camel run labs/05-mcp/mcp.camel.yaml platform/SandboxTrust.java --runtime=quarkus --port=8081` + deps | `curl http://127.0.0.1:8081/mcp` y `/ask` desde otra terminal |
| Inner — Stop | `camel stop` | `camel ps` vacío |

El workspace de Dev Spaces también es un pod de tu proyecto y cuenta en la misma cuota. El devfile pide 512Mi / 200m de request y limita el contenedor a 4Gi / 2 CPU (el IDE más Camel JBang).

## Abrir el repo en Dev Spaces

1. Pulsá el botón **Open in Developer Sandbox** arriba, o entrá al Developer Sandbox, abrí la consola de OpenShift y, en el lanzador de aplicaciones (los nueve puntos), abrí **OpenShift Dev Spaces**.
2. Si no usaste el botón: **Create Workspace** y pegá la URL de este repo: `https://github.com/maximilianoPizarro/camel-k-devsandbox`.
3. Dev Spaces lee el [`devfile.yaml`](devfile.yaml) de la raíz y clona el repo en el workspace. La guía de ese flujo está en [Get started with OpenShift Dev Spaces](https://docs.redhat.com/en/documentation/red_hat_openshift_dev_spaces/3.28/html/user_guide/assembly_getting-started_user_guide).
4. Esperá a que el workspace arranque. `oc whoami` y `oc project` ya apuntan a tu usuario y a tu proyecto `*-dev`. No copies un token dentro del repo ni del README.

Los commands del devfile aparecen como tareas del IDE. La documentación lo describe en [Customize workspace components](https://docs.redhat.com/en/documentation/red_hat_openshift_dev_spaces/3.28/html/user_guide/assembly_customizing-workspaces_user_guide): **Terminal → Run Task…**, o `F1` y escribí `task`. El esquema de esos commands está en [Defining commands](https://devfile.io/docs/2.2.2/defining-commands).

Ningún paso corre solo al abrir el workspace. Elegís la tarea cuando querés avanzar.

## Tres vistas del mismo lab

**La tarea.** Las tareas **Outer — …** corren `scripts/up.sh`. Ese script borra el lab anterior, sincroniza el YAML de Kaoto con el Integration y hace `oc apply`. La salida te dice el nombre del Deployment y, si hay HTTP, la URL de la Route. Las tareas **Inner — …** corren el mismo `*.camel.yaml` con `camel run` dentro del workspace. El comando aparece directo en el [`devfile.yaml`](devfile.yaml) para que lo copies a cualquier terminal.

**La consola de OpenShift.** En la barra de estado del IDE, **Dev Spaces → Open OpenShift Console**. Cambiá a la perspectiva **Developer**, elegí tu proyecto y abrí **Topology**. Ahí ves el Deployment de la Integration, el pod y la flecha de la Route. Los logs están en el pod. La vista está documentada en [Viewing application composition using the Topology view](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/building_applications/odc-viewing-application-composition-using-topology-view).

**Kaoto.** El workspace recomienda la extensión `redhat.vscode-kaoto`. Dev Spaces la instala al arrancar si el registry Open VSX la tiene, que es el mecanismo de [Automate installation of VS Code extensions](https://docs.redhat.com/en/documentation/red_hat_openshift_dev_spaces/3.28/html/user_guide/assembly_customizing-workspaces_user_guide#automate-installation-of-vs-code-extensions-at-workspace-startup_user_guide). Abrí el `*.camel.yaml` del paso: Kaoto muestra el canvas de esa ruta. Si el registry embebido del sandbox no tiene la extensión, instalala desde el VSIX de [redhat.vscode-kaoto en Open VSX](https://open-vsx.org/extension/redhat/vscode-kaoto) con `F1` → **Extensions: Install from VSIX…**. La instalación general está en [Kaoto installation](https://kaoto.io/docs/installation/).

Kaoto edita el `*.camel.yaml`. [`scripts/sync.py`](scripts/sync.py) copia ese flujo dentro de `spec.flows` del Integration antes de aplicar. Si cambiaste el canvas, volvé a correr el mismo paso para publicar el cambio.

## Misma ruta: Kaoto, JBang y el operador

El archivo `*.camel.yaml` de cada lab es el que abre Kaoto. Hay dos formas de ejecutarlo:

1. **Camel JBang en el workspace** (tareas **Inner — …**). El proceso corre en el contenedor de Dev Spaces. No crea un Integration. Hello y HTTP no necesitan el cluster. Kafka usa solo el Deployment `kafka`. Granite y MCP llaman al predictor de OpenShift AI desde el workspace. El HTTP local usa el puerto **8081** porque el IDE ya ocupa el 8080.
2. **Operador Camel K** (Outer — Hello … Outer — MCP). `sync.py` copia el flujo al Integration y el operador construye la imagen en tu proyecto.

La instalación del CLI está en [Camel CLI — Getting Started](https://camel.apache.org/manual/camel-jbang-getting-started.html). Este workshop fija la versión 4.22.0 como en [Installation Options](https://camel.apache.org/manual/camel-jbang-installation.html). Las opciones de `camel run` están en [camel run](https://camel.apache.org/manual/jbang-commands/camel-jbang-run.html). La primera tarea Inner que corras instala JBang y el CLI automáticamente (`source scripts/install-jbang.sh`). El home es efímero: si recreás el workspace, se vuelve a instalar con la primera tarea.

## Cuota y por qué hay un solo lab vivo

En el sandbox de referencia la cuota de pods largos es 3 CPU de request y 30Gi de memoria, sin GPU. Los builds de OpenShift tienen otra cuota (3 CPU y 14Gi). El LimitRange del proyecto pone 1 CPU y 1000Mi de limit a todo contenedor que no declara recursos. Todos los manifiestos de este repo declaran request y limit.

Sin un `IntegrationPlatform` en tu proyecto, el operador publica la imagen del kit en el namespace `camel-k-operator`. Ese registry no acepta el pull de tu ServiceAccount, y el pod queda en `ImagePullBackOff`. [`scripts/platform.sh`](scripts/platform.sh) crea el IntegrationPlatform `camel-k` para que la imagen quede en un ImageStream de tu proyecto. El build usa la estrategia `routine` (corre dentro del operador) y publica con `S2I`. Un pod builder no sirve en este sandbox: el usuario no puede delegar `builds/status`, y sin eso el builder no puede cerrar el Build. `up.sh` corre ese script antes de cada lab. El primer build baja dependencias Maven y puede tardar varios minutos. No crea un pod de build en tu cuota.

El workspace, un Integration y, en el paso 3, el broker entran juntos. Igual cada paso borra al anterior para no acumular Routes, pods ni el broker mientras avanzás. Antes de correr una tarea Inner, conviene limpiar el lab del operador con **Outer — Clean** para no sumar dos JVMs de Camel a la cuota. La regla de cuota por proyecto está en [Resource quotas](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/working_with_quotas/quotas-setting-per-project-quotas). El artículo [Try Camel K in the Developer Sandbox](https://developers.redhat.com/articles/2023/03/30/try-camel-k-developer-sandbox-red-hat-openshift) muestra el mismo modelo: el operador vive fuera de tu proyecto y reacciona al Integration que creás. La configuración del registry está en [Camel K registry](https://camel.apache.org/camel-k/2.11.x/installation/registry.html) y en `oc explain integrationplatform.spec.build`.

Para ver el consumo en cualquier momento: **Terminal → Run Task… → Estado del proyecto**, o `bash scripts/status.sh`.

Los recursos de los labs llevan `app.kubernetes.io/part-of=camel-k-workshop`. **Outer — Clean** borra Integrations, Deployments, Services, Routes, ConfigMaps y Secrets con esa etiqueta. No toca el IntegrationPlatform `camel-k`, los CamelCatalog ni el Service `modelmesh-serving`. **Outer — Clean** **no** detiene Camel JBang: para eso está **Inner — Stop**.

## Outer — Hello

**Objetivo.** Comprobar que el operador construye y levanta una Integration.

**Objetos.** Un Integration `hello`. El operador crea el Deployment y el pod. No hay Route.

**Ruta.** [`labs/01-hello/hello.camel.yaml`](labs/01-hello/hello.camel.yaml)

1. `timer:tick` dispara cada 10 segundos.
2. `setBody` fija el saludo.
3. `log` lo escribe en stdout del pod.

**Tarea.** Outer — Hello. La misma ruta en el workspace: **Inner — Hello** (el log sale en la terminal de la tarea, sin Deployment).

**Consola.** Topology → Deployment `hello` → pod → **Logs**. La línea esperada es `hello Hola desde Camel K en Developer Sandbox`. El primer build puede tardar varios minutos. La tarea espera la condición `Ready`.

**Kaoto.** Abrí `labs/01-hello/hello.camel.yaml`.

**Todas las opciones**

- [timer](https://camel.apache.org/components/4.22.x/timer-component.html) y [log](https://camel.apache.org/components/4.22.x/log-component.html)
- [YAML DSL](https://camel.apache.org/manual/yaml-dsl.html)
- [Running an Integration](https://camel.apache.org/camel-k/next/running/running.html)
- Traits usados: [container](https://camel.apache.org/camel-k/next/traits/container.html) (CPU, memoria, `runAsNonRoot`) y [logging](https://camel.apache.org/camel-k/next/traits/logging.html) si tu versión del manual lo publica; si no, `oc explain integration.spec.traits.logging`
- Índice de traits del CRD instalado: `oc explain integration.spec.traits` y la [lista de traits](https://camel.apache.org/camel-k/next/traits/traits.html)
- [API del Integration](https://camel.apache.org/camel-k/next/apis/camel-k.html)

Anotá `phase` e `image` que imprime la tarea, y en el log la línea `Apache Camel 4.22.0`. Los enlaces de componentes de esta guía son de esa línea.

## Outer — HTTP

**Objetivo.** Exponer una ruta con `platform-http` y abrirla desde la Route de OpenShift.

**Objetos.** Integration `http-hello`, Service y Route. En Camel K 2.11 el trait `ingress` solo corre con perfil Kubernetes. Este sandbox es OpenShift, así que el IntegrationPlatform fija `profile: OpenShift` y el trait `route` crea la Route con `tlsTermination: edge`. Está marcado como deprecado en el CRD, pero es el que publica el host `https://`. `oc explain integration.spec.traits.route` y [ingress](https://camel.apache.org/camel-k/2.11.x/traits/ingress.html).

**Ruta.** [`labs/02-http/hello.camel.yaml`](labs/02-http/hello.camel.yaml). `platform-http:/hello` acepta solo GET, fija `Content-Type` y devuelve `Hola desde platform-http`.

**Tarea.** Outer — HTTP. Reemplaza a Outer — Hello. En el workspace: **Inner — HTTP** sirve el mismo YAML en `http://127.0.0.1:8081/hello` (sin Route de OpenShift).

**Consola.** Topology → nodo `http-hello` → la flecha de la Route abre `https://<route>/hello`. La tarea también hace ese `curl` y muestra el cuerpo.

**Kaoto.** `labs/02-http/hello.camel.yaml`.

**Todas las opciones**

- [platform-http](https://camel.apache.org/components/4.22.x/platform-http-component.html): métodos, path, puerto y el consumer que dispara el Service
- [route](https://camel.apache.org/camel-k/2.11.x/traits/route.html): host y TLS. Es el trait que crea la Route con perfil OpenShift
- [ingress](https://camel.apache.org/camel-k/2.11.x/traits/ingress.html): el equivalente cuando el perfil es Kubernetes
- [container](https://camel.apache.org/camel-k/next/traits/container.html): `expose` y `port` (el puerto por defecto del HTTP de Camel es 8080)
- [choice EIP](https://camel.apache.org/components/4.22.x/eips/choice-eip.html) y el resto de los EIP en el [índice 4.22.x](https://camel.apache.org/components/4.22.x/index.html)

## Outer — Kafka

**Objetivo.** Publicar y consumir en un broker chico, sin instalar el operador de Strimzi. En este sandbox el usuario no tiene el CRD de Kafka de Strimzi.

**Objetos.**

- Deployment `kafka` y Service `kafka:9092`, un solo nodo KRaft, sin PVC (`emptyDir`). La imagen es `quay.io/strimzi/kafka:0.46.0-kafka-3.9.0`: es el binario, no el operador.
- Request 100m / 384Mi, limit 500m / 768Mi, heap `-Xmx384m`.
- Integration `orders` con dos rutas en el mismo pod: un timer publica `pedido A-100` en el topic `orders` y un consumer lo loguea. El timer espera 20 segundos para darle tiempo al consumer a suscribirse.

El listener de clientes es PLAINTEXT y solo se anuncia dentro del namespace (`advertised.listeners=PLAINTEXT://kafka:9092`). El controller de KRaft escucha en `127.0.0.1:9093`: Kafka 3.9 rechaza `0.0.0.0` como dirección anunciada del controller. No lo expongas con una Route.

**Tarea.** Outer — Kafka. La tarea espera el rollout del broker y después la Integration. En el workspace: **Inner — Kafka** sube solo el broker y corre `orders.camel.yaml` con JBang (sin Integration `orders`).

**Consola.** Topology muestra el Deployment `kafka` y el Deployment `orders`. En los logs de `orders` tienen que aparecer `publicado pedido A-100` y `pedido recibido pedido A-100`. La primera línea del consumer puede tardar hasta el primer tick de 15 segundos, después de la espera inicial.

**Kaoto.** `labs/03-kafka/orders.camel.yaml`. El Deployment del broker está en [`labs/03-kafka/kafka.yaml`](labs/03-kafka/kafka.yaml), no en el canvas.

**Todas las opciones**

- [kafka component](https://camel.apache.org/components/4.22.x/kafka-component.html): `brokers`, `groupId`, `autoOffsetReset`, consumidores y productores
- [KRaft](https://kafka.apache.org/documentation/#kraft): modo del broker de un nodo, sin ZooKeeper
- [direct](https://camel.apache.org/components/4.22.x/direct-component.html) queda para Outer — MCP, cuando una ruta llama a otra dentro del mismo proceso
- [builder](https://camel.apache.org/camel-k/next/traits/builder.html): estrategias `routine` y `pod`, y los requests del build si alguna vez pasás a `pod`

## Outer — Granite

**Objetivo.** Llamar desde la Integration a un modelo que ya sirve OpenShift AI, sin desplegar un modelo en tu proyecto. Tu cuota de GPU es 0.

**Modelo.** `isvc-granite-31-8b-fp8` en

`https://isvc-granite-31-8b-fp8-predictor.sandbox-shared-models.svc.cluster.local:8443/v1/chat/completions`

Esa URL solo resuelve dentro del cluster. La Route del lab es la que abrís desde la consola. El recorrido de los modelos del sandbox está en [Get started with consuming GPU-hosted large language models on Developer Sandbox](https://developers.redhat.com/learn/ai/get-started-consuming-gpu-hosted-large-language-models-developer-sandbox) y el `curl` de referencia en [Interact with the hosted models using curl](https://developers.redhat.com/learning/learn:ai:get-started-consuming-gpu-hosted-large-language-models-developer-sandbox/resource/resources:interact-hosted-models-using-curl).

**Objetos.** Secret `sandbox-llm-token` (lo crea la tarea con `oc whoami -t`; no está en git y Outer — Clean lo borra) e Integration `granite`. El trait [environment](https://camel.apache.org/camel-k/next/traits/environment.html) inyecta `LLM_TOKEN=secret:sandbox-llm-token/token`. El token del sandbox vence: si `/ask` responde 401, volvé a correr Outer — Granite.

**Ruta.** [`labs/04-granite/ask.camel.yaml`](labs/04-granite/ask.camel.yaml)

1. `GET /ask` usa la pregunta por defecto: *Explica el patrón Content-Based Router de Enterprise Integration Patterns en dos frases*. `GET /ask?q=...` usa el query que le pases. Escribí `q` en texto plano, sin comillas dobles: el cuerpo JSON se arma con esa cadena. El modelo no tiene reloj ni internet: preguntas como "qué hora es" van a fallar.
2. Arma un chat completion de la API compatible con OpenAI.
3. Borra los headers `CamelHttp*` y `Host` que llegaron con el GET, y hace POST al predictor con el Bearer, el bean `sandboxSsl` y `bridgeEndpoint=true`. Si no, el componente HTTP reenvía el path `/ask` o el host de la Route y el modelo responde 404. La opción está en [http](https://camel.apache.org/components/4.22.x/http-component.html).
4. Si el HTTP es 200, devuelve `choices[0].message.content`. Si no, devuelve el código y el cuerpo.

**TLS.** El predictor presenta un certificado firmado por la CA de servicio de OpenShift. Esa CA está en cada pod en `/var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt`. [`platform/SandboxTrust.java`](platform/SandboxTrust.java) la carga en un `SSLContextParameters` registrado como `sandboxSsl`. No desactiva la verificación del nombre. El trait [mount](https://camel.apache.org/camel-k/next/traits/mount.html) sirve para montar otros ConfigMaps o Secrets; este archivo ya viene montado por OpenShift.

**Tarea.** Outer — Granite. La tarea hace `curl` a `/ask` y muestra el texto del modelo. La primera respuesta puede tardar. En el workspace: **Inner — Granite** usa el mismo YAML y `SandboxTrust.java` en el puerto 8081; el token va en la variable de entorno del proceso, no a un Secret.

**Ejemplos de queries.** Probá desde la consola o desde otra terminal del workspace:

```
curl -k "https://<route>/ask?q=Escribe+una+ruta+Apache+Camel+en+YAML+que+lea+de+Kafka+y+escriba+en+un+log"
curl -k "https://<route>/ask?q=Que+ventaja+tiene+publicar+una+integracion+como+herramienta+MCP+en+lugar+de+API+REST"
curl -k "https://<route>/ask?q=Que+hace+el+componente+platform-http+de+Apache+Camel"
```

**Consola.** Abrí la flecha de la Route. La raíz no es `/ask`: sumá `/ask` al final de la URL.

**Kaoto.** `labs/04-granite/ask.camel.yaml`. El bean Java no aparece en el canvas; el `to` HTTPS sí.

**Otra forma de llamar al modelo.** Este paso usa el componente HTTP para que el request quede visible en la ruta. Camel 4.22 también trae el cliente de chat y las herramientas de LangChain4j:

- [langchain4j-chat](https://camel.apache.org/components/4.22.x/langchain4j-chat-component.html)
- [langchain4j-tools](https://camel.apache.org/components/4.22.x/langchain4j-tools-component.html)
- [http](https://camel.apache.org/components/4.22.x/http-component.html), que es el que usa el `https:` de la ruta

Para apuntar a Qwen o a Nemotron, cambiá el id y el host en el `setBody` y en el `to`. Los tres están Ready en `sandbox-shared-models`:

- Granite 3.1 8B: `isvc-granite-31-8b-fp8`
- Qwen 3 8B: `isvc-qwen3-8b-fp8` en `https://isvc-qwen3-8b-fp8-predictor.sandbox-shared-models.svc.cluster.local:8443/v1/chat/completions`
- Nemotron Nano 9B v2: `isvc-nemotron-nano-9b-v2-fp8` en `https://isvc-nemotron-nano-9b-v2-fp8-predictor.sandbox-shared-models.svc.cluster.local:8443/v1/chat/completions`

## Outer — MCP

**Objetivo.** Publicar una ruta como herramienta MCP y usar el mismo estado como contexto de Granite.

Camel 4.22 trae [MCP Server](https://camel.apache.org/components/4.22.x/others/mcp-server.html). En Quarkus lo sirve la extensión [camel-quarkus-mcp-server](https://camel.apache.org/camel-quarkus/3.40.x/reference/extensions/mcp-server.html): no hay una ruta que arme el JSON-RPC. Las dependencias Maven `camel-quarkus-ai-tool` y `camel-quarkus-mcp-server` 3.39.0, más la property de build `quarkus.camel.mcp-server.tags=orders` (el trait `builder`, porque Quarkus la fija al construir), exponen las rutas `ai-tool` cuyo tag coincide. Van como `mvn:` porque el CamelCatalog que el operador valida en este sandbox es 3.15.3 y no conoce esos artifacts, aunque el kit que construye es Camel 4.22. `scripts/platform.sh` igual los registra en el catalogo del proyecto. El endpoint queda en `POST /mcp` ([streamable HTTP](https://modelcontextprotocol.io/specification/2024-11-05)). El cliente manda `Accept: application/json, text/event-stream` y, si el servidor lo devuelve, el header `Mcp-Session-Id`.

**Rutas.** [`labs/05-mcp/mcp.camel.yaml`](labs/05-mcp/mcp.camel.yaml)

- `direct:order-status` devuelve un texto fijo para `A-100`, `B-200` y `C-300`.
- `ai-tool:order-status` (tag `orders`) toma `orderId` del header y llama a `direct:order-status`. Esa es la herramienta MCP.
- `platform-http:/ask` llama la misma lógica (por defecto `A-100`, o `?orderId=B-200`) y le pide a Granite una frase.

**Tarea.** Outer — MCP. Imprime `initialize`, `tools/list`, `tools/call` de `A-100` y el `GET /ask?orderId=B-200`. En el workspace: **Inner — MCP** usa `--runtime=quarkus` para fijar `quarkus.camel.mcp-server.tags=orders` al construir. El proceso queda en primer plano; probá `curl http://127.0.0.1:8081/mcp` desde otra terminal.

**Probar MCP manualmente.** La tarea Outer — MCP hace estos curls automáticamente. Para probar desde otra terminal (cambiá `HOST` por la Route del cluster o `127.0.0.1:8081` en Inner):

```bash
# Variable con el host (operador)
HOST=$(oc get route/mcp -o jsonpath='{.spec.host}')
# O para Inner — MCP:  HOST=127.0.0.1:8081

# 1. initialize — devuelve capabilities y el Mcp-Session-Id
curl -ksS -D /tmp/mcp-hdr \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"workshop","version":"0.1.0"}}}' \
  "https://${HOST}/mcp"

# 2. Capturar session id
SID=$(awk 'tolower($1)=="mcp-session-id:" {print $2}' /tmp/mcp-hdr | tr -d '\r')

# 3. tools/list — tiene que incluir order-status
curl -ksS \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H "Mcp-Session-Id: ${SID}" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
  "https://${HOST}/mcp"

# 4. tools/call — llama la herramienta
curl -ksS \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H "Mcp-Session-Id: ${SID}" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"order-status","arguments":{"orderId":"A-100"}}}' \
  "https://${HOST}/mcp"

# 5. /ask — Granite redacta el estado del pedido
curl -ksS --max-time 180 "https://${HOST}/ask?orderId=B-200"
```

| Llamada | Respuesta esperada |
| --- | --- |
| `initialize` | `serverInfo.name` = `camel-k-workshop`, `capabilities.tools` presente |
| `tools/list` | Herramienta `order-status` con parámetro `orderId` |
| `tools/call` A-100 | `Pedido A-100 enviado desde Cordoba` |
| `/ask?orderId=B-200` | Granite redacta algo como *"El pedido B-200 está en preparación en Rosario"* |

Si `tools/list` viene vacío, el tag `orders` no llegó al build. Buscá en el log `No MCP tags configured`.

**Consola.** La Route sirve `/mcp` y `/ask` en el mismo host. Topology muestra un Deployment, `mcp`.

**Kaoto.** `labs/05-mcp/mcp.camel.yaml`. El canvas muestra las tres rutas. El servidor MCP no es una ruta: sale de las dependencias Maven y de `quarkus.camel.mcp-server.tags` en el trait `builder`.

**Todas las opciones**

- [ai-tool](https://camel.apache.org/components/4.22.x/ai-tool-component.html) y [MCP Server](https://camel.apache.org/components/4.22.x/others/mcp-server.html)
- [camel-quarkus-mcp-server](https://camel.apache.org/camel-quarkus/3.40.x/reference/extensions/mcp-server.html): `quarkus.camel.mcp-server.tags` y `quarkus.mcp.server.http.root-path`
- [direct](https://camel.apache.org/components/4.22.x/direct-component.html) para compartir la lógica entre la herramienta y `/ask`
- [Spec MCP 2024-11-05](https://modelcontextprotocol.io/specification/2024-11-05)
- [Camel Routes as AI Tools](https://camel.apache.org/blog/2026/08/camel-ai-tools-mcp-422/)
- [langchain4j-tools](https://camel.apache.org/components/4.22.x/langchain4j-tools-component.html) si preferís que el modelo elija la herramienta dentro de Camel, en lugar de orquestarlo en la ruta

## Si algo no levanta

**Pod Pending.** `oc describe pod <nombre>` y la cuota: `oc get resourcequota compute-deploy`. Un workspace más el broker más una Integration entra en la cuota de referencia. Si hay otro Deployment tuyo, corré Outer — Clean o **Dev Spaces: Stop Workspace** desde la barra de estado antes de volver a entrar.

**Integration en Error.** `oc describe integration <nombre>` y `oc describe build.camel.apache.org`. El mensaje queda en `status.error` del Build. La referencia de fases está en [Running an Integration](https://camel.apache.org/camel-k/next/running/running.html).

**ImagePullBackOff.** La imagen del kit se publicó en `camel-k-operator`. Volvé a correr el paso: `scripts/platform.sh` deja el IntegrationPlatform `camel-k` en tu proyecto para que el ImageStream sea local. No borres ese IntegrationPlatform.

**401 del modelo.** El token venció. Volvé a correr Outer — Granite o Outer — MCP (o Inner — Granite / Inner — MCP). La tarea recrea el Secret o exporta `LLM_TOKEN` otra vez.

**PKIX o hostname en Outer — Granite o Outer — MCP.** El predictor no presentó la CA de `service-ca.crt`, o el nombre del certificado no coincide con el host del Service. El mensaje queda en el log de la Integration y en el cuerpo de `/ask`.

**Kaoto no aparece.** El registry embebido de Dev Spaces a veces no tiene `redhat.vscode-kaoto`. Instalá el VSIX desde [Open VSX](https://open-vsx.org/extension/redhat/vscode-kaoto). La lista de formatos que abre el editor está en la [documentación de Kaoto](https://kaoto.io/docs/).

**La Route no abre.** `oc get route`. El host es el de tu proyecto. Sumá el path (`/hello`, `/ask` o `/mcp`).

**Camel JBang no está.** La primera tarea Inner lo instala. Para instalarlo manualmente, abrí una terminal y corré: `source scripts/install-jbang.sh`.

**Puerto 8080 ocupado.** Las tareas Inner HTTP, Granite y MCP usan el **8081**. No uses `--port 8080` en el workspace: ahí escucha el IDE.

**OOM en el workspace.** El contenedor limita a 4Gi. Detené JBang con **Inner — Stop** y bajá el lab del operador con Outer — Clean antes de volver a correr Inner — MCP (el build Quarkus es el más pesado).

**`tools/list` vacío en Inner — MCP.** El tag `orders` no llegó al build Quarkus. Revisá que el comando incluya `--property=quarkus.camel.mcp-server.tags=orders` (mirá el `devfile.yaml`).

**Outer — Clean no detiene JBang.** Solo borra recursos del cluster con la etiqueta del workshop. Para el proceso local usá **Inner — Stop**.

## Índice de documentación

Camel K

- [Running an Integration](https://camel.apache.org/camel-k/next/running/running.html)
- [Traits](https://camel.apache.org/camel-k/next/traits/traits.html)
- [container](https://camel.apache.org/camel-k/next/traits/container.html)
- [route](https://camel.apache.org/camel-k/2.11.x/traits/route.html)
- [ingress](https://camel.apache.org/camel-k/2.11.x/traits/ingress.html)
- [builder](https://camel.apache.org/camel-k/next/traits/builder.html)
- [camel](https://camel.apache.org/camel-k/next/traits/camel.html) (properties y `runtimeVersion`)
- [environment](https://camel.apache.org/camel-k/next/traits/environment.html)
- [mount](https://camel.apache.org/camel-k/next/traits/mount.html)
- [API de Integration](https://camel.apache.org/camel-k/next/apis/camel-k.html)
- En el cluster: `oc explain integration.spec.traits`

Camel 4.22, la línea que construye el operador del sandbox

- [Índice de componentes](https://camel.apache.org/components/4.22.x/index.html)
- [YAML DSL](https://camel.apache.org/manual/yaml-dsl.html)
- [timer](https://camel.apache.org/components/4.22.x/timer-component.html)
- [log](https://camel.apache.org/components/4.22.x/log-component.html)
- [platform-http](https://camel.apache.org/components/4.22.x/platform-http-component.html)
- [direct](https://camel.apache.org/components/4.22.x/direct-component.html)
- [kafka](https://camel.apache.org/components/4.22.x/kafka-component.html)
- [http](https://camel.apache.org/components/4.22.x/http-component.html)
- [langchain4j-chat](https://camel.apache.org/components/4.22.x/langchain4j-chat-component.html)
- [langchain4j-tools](https://camel.apache.org/components/4.22.x/langchain4j-tools-component.html)
- [choice](https://camel.apache.org/components/4.22.x/eips/choice-eip.html)
- [JSON data format](https://camel.apache.org/components/4.22.x/dataformats/json-dataformat.html)

Camel JBang

- [Camel CLI — Getting Started](https://camel.apache.org/manual/camel-jbang-getting-started.html)
- [Installation Options](https://camel.apache.org/manual/camel-jbang-installation.html) (versión fija)
- [camel run](https://camel.apache.org/manual/jbang-commands/camel-jbang-run.html)
- [Managing integrations](https://camel.apache.org/manual/camel-jbang-managing.html) (`camel ps`, `camel stop`)

Kaoto, Dev Spaces y OpenShift

- [Instalación de Kaoto](https://kaoto.io/docs/installation/)
- [Documentación de Kaoto](https://kaoto.io/docs/)
- [Extensión en Open VSX](https://open-vsx.org/extension/redhat/vscode-kaoto)
- [Get started with OpenShift Dev Spaces](https://docs.redhat.com/en/documentation/red_hat_openshift_dev_spaces/3.28/html/user_guide/assembly_getting-started_user_guide)
- [Customize workspace components](https://docs.redhat.com/en/documentation/red_hat_openshift_dev_spaces/3.28/html/user_guide/assembly_customizing-workspaces_user_guide)
- [Defining commands](https://devfile.io/docs/2.2.2/defining-commands)
- [Topology view](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/building_applications/odc-viewing-application-composition-using-topology-view)
- [Resource quotas](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/working_with_quotas/quotas-setting-per-project-quotas)
- [Try Camel K in the Developer Sandbox](https://developers.redhat.com/articles/2023/03/30/try-camel-k-developer-sandbox-red-hat-openshift)

OpenShift AI y MCP

- [Modelos GPU del Developer Sandbox](https://developers.redhat.com/learn/ai/get-started-consuming-gpu-hosted-large-language-models-developer-sandbox)
- [curl contra los modelos](https://developers.redhat.com/learning/learn:ai:get-started-consuming-gpu-hosted-large-language-models-developer-sandbox/resource/resources:interact-hosted-models-using-curl)
- [Spec MCP 2024-11-05](https://modelcontextprotocol.io/specification/2024-11-05)
- [camel-mcp-server 4.22](https://camel.apache.org/components/4.22.x/others/mcp-server.html)
- [KRaft](https://kafka.apache.org/documentation/#kraft)
