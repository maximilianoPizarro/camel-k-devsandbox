# Camel K en Developer Sandbox

Workshop para recorrer Apache Camel K dentro de un workspace de [OpenShift Dev Spaces](https://docs.redhat.com/en/documentation/red_hat_openshift_dev_spaces/3.28/html/user_guide/assembly_getting-started_user_guide) en el mismo [Developer Sandbox](https://developers.redhat.com/developer-sandbox). Cada paso es una tarea del `devfile.yaml`. El paso siguiente borra el anterior, así en el proyecto queda un solo ejemplo vivo.

El operador Camel K ya está instalado en el sandbox y observa tu proyecto. Estos labs no instalan otro operador. El catálogo publicado en el namespace de referencia es Camel 4.8.5 / Quarkus 3.15.3. El Paso 1 imprime el runtime que quedó en la Integration por si el operador resuelve otro catálogo.

## Qué vas a dejar corriendo

| Paso | Tarea en Dev Spaces | Qué crea | Qué mirar |
| --- | --- | --- | --- |
| 0 | Paso 0 — Limpiar el lab activo | Borra lo etiquetado por el workshop | Topology vacío de estos labs |
| 1 | Paso 1 — Hello | Integration `hello` | Log `hello Hola desde Camel K...` |
| 2 | Paso 2 — HTTP | Integration `http-hello` y su Route | `GET /hello` |
| 3 | Paso 3 — Kafka | Deployment `kafka` e Integration `orders` | Log `pedido recibido pedido A-100` |
| 4 | Paso 4 — Granite | Integration `granite`, Secret del token y Route | Texto del modelo en `GET /ask` |
| 5 | Paso 5 — MCP | Integration `mcp`, Secret del token y Route | `tools/list`, `tools/call` y `GET /ask` |

El workspace de Dev Spaces también es un pod de tu proyecto y cuenta en la misma cuota. El devfile pide 512Mi / 200m de request y limita el contenedor a 2Gi / 1 CPU.

## Abrir el repo en Dev Spaces

1. Entrá al Developer Sandbox y abrí la consola de OpenShift.
2. En el lanzador de aplicaciones (los nueve puntos) abrí **OpenShift Dev Spaces**.
3. **Create Workspace** y pegá la URL de este repo: `https://github.com/maximilianoPizarro/camel-k-devsandbox`.
4. Dev Spaces lee el [`devfile.yaml`](devfile.yaml) de la raíz y clona el repo en el workspace. La guía de ese flujo está en [Get started with OpenShift Dev Spaces](https://docs.redhat.com/en/documentation/red_hat_openshift_dev_spaces/3.28/html/user_guide/assembly_getting-started_user_guide).
5. Esperá a que el workspace arranque. `oc whoami` y `oc project` ya apuntan a tu usuario y a tu proyecto `*-dev`. No copies un token dentro del repo ni del README.

Los commands del devfile aparecen como tareas del IDE. La documentación lo describe en [Customize workspace components](https://docs.redhat.com/en/documentation/red_hat_openshift_dev_spaces/3.28/html/user_guide/assembly_customizing-workspaces_user_guide): **Terminal → Run Task…**, o `F1` y escribí `task`. El esquema de esos commands está en [Defining commands](https://devfile.io/docs/2.2.2/defining-commands).

Ningún paso corre solo al abrir el workspace. Elegís la tarea cuando querés avanzar.

## Tres vistas del mismo lab

**La tarea.** Corre `scripts/up.sh`. Ese script borra el lab anterior, sincroniza el YAML de Kaoto con el Integration y hace `oc apply`. La salida te dice el nombre del Deployment y, si hay HTTP, la URL de la Route.

**La consola de OpenShift.** En la barra de estado del IDE, **Dev Spaces → Open OpenShift Console**. Cambiá a la perspectiva **Developer**, elegí tu proyecto y abrí **Topology**. Ahí ves el Deployment de la Integration, el pod y la flecha de la Route. Los logs están en el pod. La vista está documentada en [Viewing application composition using the Topology view](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/building_applications/odc-viewing-application-composition-using-topology-view).

**Kaoto.** El workspace recomienda la extensión `redhat.vscode-kaoto`. Dev Spaces la instala al arrancar si el registry Open VSX la tiene, que es el mecanismo de [Automate installation of VS Code extensions](https://docs.redhat.com/en/documentation/red_hat_openshift_dev_spaces/3.28/html/user_guide/assembly_customizing-workspaces_user_guide#automate-installation-of-vs-code-extensions-at-workspace-startup_user_guide). Abrí el `*.camel.yaml` del paso: Kaoto muestra el canvas de esa ruta. Si el registry embebido del sandbox no tiene la extensión, instalala desde el VSIX de [redhat.vscode-kaoto en Open VSX](https://open-vsx.org/extension/redhat/vscode-kaoto) con `F1` → **Extensions: Install from VSIX…**. La instalación general está en [Kaoto installation](https://kaoto.io/docs/installation/).

Kaoto edita el `*.camel.yaml`. [`scripts/sync.py`](scripts/sync.py) copia ese flujo dentro de `spec.flows` del Integration antes de aplicar. Si cambiaste el canvas, volvé a correr el mismo paso para publicar el cambio.

## Cuota y por qué hay un solo lab vivo

En el sandbox de referencia la cuota de pods largos es 3 CPU de request y 30Gi de memoria, sin GPU. Los builds efímeros tienen otra cuota (3 CPU y 14Gi). El trait `builder` de este operador usa la estrategia `routine`: el build corre en el operador, no como pod de tu proyecto. No la cambies a `pod`.

El LimitRange del proyecto pone 1 CPU y 1000Mi de limit a todo contenedor que no declara recursos. Todos los manifiestos de este repo declaran request y limit.

El workspace, un Integration y, en el paso 3, el broker entran juntos. Igual cada paso borra al anterior para no acumular Routes, pods ni el broker mientras avanzás. La regla de cuota por proyecto está en [Resource quotas](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/working_with_quotas/quotas-setting-per-project-quotas). El artículo [Try Camel K in the Developer Sandbox](https://developers.redhat.com/articles/2023/03/30/try-camel-k-developer-sandbox-red-hat-openshift) muestra el mismo modelo: el operador vive fuera de tu proyecto y reacciona al Integration que creás.

Para ver el consumo en cualquier momento: **Terminal → Run Task… → Estado del proyecto**, o `bash scripts/status.sh`.

Los recursos de los labs llevan `app.kubernetes.io/part-of=camel-k-workshop`. El Paso 0 borra Integrations, Deployments, Services, Routes, ConfigMaps y Secrets con esa etiqueta. No toca los CamelCatalog ni el Service `modelmesh-serving`, que vienen con el proyecto.

## Paso 1 — Hello

**Objetivo.** Comprobar que el operador construye y levanta una Integration.

**Objetos.** Un Integration `hello`. El operador crea el Deployment y el pod. No hay Route.

**Ruta.** [`labs/01-hello/hello.camel.yaml`](labs/01-hello/hello.camel.yaml)

1. `timer:tick` dispara cada 10 segundos.
2. `setBody` fija el saludo.
3. `log` lo escribe en stdout del pod.

**Tarea.** Paso 1 — Hello.

**Consola.** Topology → Deployment `hello` → pod → **Logs**. La línea esperada es `hello Hola desde Camel K en Developer Sandbox`. El primer build puede tardar varios minutos. La tarea espera la condición `Ready`.

**Kaoto.** Abrí `labs/01-hello/hello.camel.yaml`.

**Todas las opciones**

- [timer](https://camel.apache.org/components/4.8.x/timer-component.html) y [log](https://camel.apache.org/components/4.8.x/log-component.html)
- [YAML DSL](https://camel.apache.org/manual/yaml-dsl.html)
- [Running an Integration](https://camel.apache.org/camel-k/next/running/running.html)
- Traits usados: [container](https://camel.apache.org/camel-k/next/traits/container.html) (CPU, memoria, `runAsNonRoot`) y [logging](https://camel.apache.org/camel-k/next/traits/logging.html) si tu versión del manual lo publica; si no, `oc explain integration.spec.traits.logging`
- Índice de traits del CRD instalado: `oc explain integration.spec.traits` y la [lista de traits](https://camel.apache.org/camel-k/next/traits/traits.html)
- [API del Integration](https://camel.apache.org/camel-k/next/apis/camel-k.html)

Anotá `phase` e `image` que imprime la tarea. Si el runtime no es 4.8.x, los links de componentes de arriba siguen siendo la referencia del catálogo 4.8.5 que este repo asume. El Paso 5 explica qué cambia si el runtime es 4.22.

## Paso 2 — HTTP

**Objetivo.** Exponer una ruta con `platform-http` y abrirla desde la Route de OpenShift.

**Objetos.** Integration `http-hello`, Service y Route. El trait `ingress.auto` crea la Route. En este CRD el trait `route` está deprecado: `oc explain integration.spec.traits.route`.

**Ruta.** [`labs/02-http/hello.camel.yaml`](labs/02-http/hello.camel.yaml). `platform-http:/hello` acepta solo GET, fija `Content-Type` y devuelve `Hola desde platform-http`.

**Tarea.** Paso 2 — HTTP. Reemplaza al Paso 1.

**Consola.** Topology → nodo `http-hello` → la flecha de la Route abre `https://<route>/hello`. La tarea también hace ese `curl` y muestra el cuerpo.

**Kaoto.** `labs/02-http/hello.camel.yaml`.

**Todas las opciones**

- [platform-http](https://camel.apache.org/components/4.8.x/platform-http-component.html): métodos, path, puerto y el consumer que dispara el trait de ingress
- [ingress](https://camel.apache.org/camel-k/next/traits/ingress.html): `auto`, host, path y anotaciones
- [container](https://camel.apache.org/camel-k/next/traits/container.html): `expose` y `port` (el puerto por defecto del HTTP de Camel es 8080)
- [choice EIP](https://camel.apache.org/components/4.8.x/eips/choice-eip.html) y el resto de los EIP en el [índice 4.8.x](https://camel.apache.org/components/4.8.x/index.html)

## Paso 3 — Kafka

**Objetivo.** Publicar y consumir en un broker chico, sin instalar el operador de Strimzi. En este sandbox el usuario no tiene el CRD de Kafka de Strimzi.

**Objetos.**

- Deployment `kafka` y Service `kafka:9092`, un solo nodo KRaft, sin PVC (`emptyDir`). La imagen es `quay.io/strimzi/kafka:0.46.0-kafka-3.9.0`: es el binario, no el operador.
- Request 100m / 384Mi, limit 500m / 768Mi, heap `-Xmx384m`.
- Integration `orders` con dos rutas en el mismo pod: un timer publica `pedido A-100` en el topic `orders` y un consumer lo loguea. El timer espera 20 segundos para darle tiempo al consumer a suscribirse.

El listener es PLAINTEXT y solo se anuncia dentro del namespace (`advertised.listeners=PLAINTEXT://kafka:9092`). No lo expongas con una Route.

**Tarea.** Paso 3 — Kafka. La tarea espera el rollout del broker y después la Integration.

**Consola.** Topology muestra el Deployment `kafka` y el Deployment `orders`. En los logs de `orders` tienen que aparecer `publicado pedido A-100` y `pedido recibido pedido A-100`. La primera línea del consumer puede tardar hasta el primer tick de 15 segundos, después de la espera inicial.

**Kaoto.** `labs/03-kafka/orders.camel.yaml`. El Deployment del broker está en [`labs/03-kafka/kafka.yaml`](labs/03-kafka/kafka.yaml), no en el canvas.

**Todas las opciones**

- [kafka component](https://camel.apache.org/components/4.8.x/kafka-component.html): `brokers`, `groupId`, `autoOffsetReset`, consumidores y productores
- [KRaft](https://kafka.apache.org/documentation/#kraft): modo del broker de un nodo, sin ZooKeeper
- [direct](https://camel.apache.org/components/4.8.x/direct-component.html) queda para el Paso 5, cuando una ruta llama a otra dentro del mismo proceso
- [builder](https://camel.apache.org/camel-k/next/traits/builder.html): estrategias `routine` y `pod`, y los requests del build si alguna vez pasás a `pod`

## Paso 4 — Granite

**Objetivo.** Llamar desde la Integration a un modelo que ya sirve OpenShift AI, sin desplegar un modelo en tu proyecto. Tu cuota de GPU es 0.

**Modelo.** `isvc-granite-31-8b-fp8` en

`https://isvc-granite-31-8b-fp8-predictor.sandbox-shared-models.svc.cluster.local:8443/v1/chat/completions`

Esa URL solo resuelve dentro del cluster. La Route del lab es la que abrís desde la consola. El recorrido de los modelos del sandbox está en [Get started with consuming GPU-hosted large language models on Developer Sandbox](https://developers.redhat.com/learn/ai/get-started-consuming-gpu-hosted-large-language-models-developer-sandbox) y el `curl` de referencia en [Interact with the hosted models using curl](https://developers.redhat.com/learning/learn:ai:get-started-consuming-gpu-hosted-large-language-models-developer-sandbox/resource/resources:interact-hosted-models-using-curl).

**Objetos.** Secret `sandbox-llm-token` (lo crea la tarea con `oc whoami -t`; no está en git y el Paso 0 lo borra) e Integration `granite`. El trait [environment](https://camel.apache.org/camel-k/next/traits/environment.html) inyecta `LLM_TOKEN=secret:sandbox-llm-token/token`. El token del sandbox vence: si `/ask` responde 401, volvé a correr el Paso 4.

**Ruta.** [`labs/04-granite/ask.camel.yaml`](labs/04-granite/ask.camel.yaml)

1. `GET /ask` usa la pregunta por defecto. `GET /ask?q=Hola` usa el query. Escribí `q` en texto plano, sin comillas dobles: el cuerpo JSON se arma con esa cadena.
2. Arma un chat completion de la API compatible con OpenAI.
3. POST al predictor con el Bearer y con el bean `sandboxSsl`.
4. Si el HTTP es 200, devuelve `choices[0].message.content`. Si no, devuelve el código y el cuerpo.

**TLS.** El predictor presenta un certificado firmado por la CA de servicio de OpenShift. Esa CA está en cada pod en `/var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt`. [`platform/SandboxTrust.java`](platform/SandboxTrust.java) la carga en un `SSLContextParameters` registrado como `sandboxSsl`. No desactiva la verificación del nombre. El trait [mount](https://camel.apache.org/camel-k/next/traits/mount.html) sirve para montar otros ConfigMaps o Secrets; este archivo ya viene montado por OpenShift.

**Tarea.** Paso 4 — Granite. La tarea hace `curl` a `/ask` y muestra el texto del modelo. La primera respuesta puede tardar.

**Consola.** Abrí la flecha de la Route. La raíz no es `/ask`: sumá `/ask` al final de la URL.

**Kaoto.** `labs/04-granite/ask.camel.yaml`. El bean Java no aparece en el canvas; el `to` HTTPS sí.

**Otra forma de llamar al modelo.** Este paso usa el componente HTTP para que el request quede visible en la ruta. Camel 4.8 también trae el cliente de chat y las herramientas de LangChain4j, que el catálogo del sandbox ya lista:

- [langchain4j-chat](https://camel.apache.org/components/4.8.x/langchain4j-chat-component.html)
- [langchain4j-tools](https://camel.apache.org/components/4.8.x/langchain4j-tools-component.html)
- [http](https://camel.apache.org/components/4.8.x/http-component.html), que es el que usa el `https:` de la ruta

Para apuntar a Qwen o a Nemotron, cambiá el id y el host en el `setBody` y en el `to`. Los tres están Ready en `sandbox-shared-models`:

- Granite 3.1 8B: `isvc-granite-31-8b-fp8`
- Qwen 3 8B: `isvc-qwen3-8b-fp8` en `https://isvc-qwen3-8b-fp8-predictor.sandbox-shared-models.svc.cluster.local:8443/v1/chat/completions`
- Nemotron Nano 9B v2: `isvc-nemotron-nano-9b-v2-fp8` en `https://isvc-nemotron-nano-9b-v2-fp8-predictor.sandbox-shared-models.svc.cluster.local:8443/v1/chat/completions`

## Paso 5 — MCP

**Objetivo.** Exponer una herramienta Camel por JSON-RPC y usar el resultado como contexto de Granite.

El catálogo 4.8.5 no incluye `camel-mcp-server`. Ese módulo llegó en Camel 4.22 y se documenta en [MCP Server](https://camel.apache.org/components/4.22.x/others/mcp-server.html): rutas `ai-tool` publicadas solas, sin armar el JSON-RPC a mano. Si el Paso 1 mostró Camel 4.22, ese es el camino nativo. Con 4.8.5 esta Integration implementa los métodos que alcanza para ver el protocolo en el canvas y probarlo con `curl`.

No es una sesión streamable HTTP completa (no negocia `Mcp-Session-Id` ni SSE). Es un POST con cuerpo JSON-RPC, el subconjunto [initialize, tools/list y tools/call de la spec 2024-11-05](https://modelcontextprotocol.io/specification/2024-11-05).

**Rutas.** [`labs/05-mcp/mcp.camel.yaml`](labs/05-mcp/mcp.camel.yaml), las tres en el mismo pod.

- `direct:order-status` devuelve un texto fijo para `A-100`, `B-200` y `C-300`.
- `platform-http:/mcp` hace `unmarshal` JSON y elige el método.
- `platform-http:/ask` llama `order-status` (por defecto `A-100`, o `?orderId=B-200`) y le pide a Granite una frase.

**Tarea.** Paso 5 — MCP. Imprime `initialize`, `tools/list`, `tools/call` de `A-100` y el `GET /ask?orderId=B-200`.

**Consola.** La Route sirve `/mcp` y `/ask` en el mismo host. Topology muestra un Deployment, `mcp`.

**Kaoto.** `labs/05-mcp/mcp.camel.yaml`. Las tres rutas aparecen en el archivo.

**Todas las opciones**

- [direct](https://camel.apache.org/components/4.8.x/direct-component.html) para llamar una ruta desde otra
- [choice](https://camel.apache.org/components/4.8.x/eips/choice-eip.html) y [unmarshal JSON](https://camel.apache.org/components/4.8.x/dataformats/json-dataformat.html)
- [Spec MCP 2024-11-05](https://modelcontextprotocol.io/specification/2024-11-05)
- [camel-mcp-server en 4.22](https://camel.apache.org/components/4.22.x/others/mcp-server.html) y el anuncio [Camel Routes as AI Tools](https://camel.apache.org/blog/2026/08/camel-ai-tools-mcp-422/)
- [langchain4j-tools](https://camel.apache.org/components/4.8.x/langchain4j-tools-component.html) si preferís que el modelo elija la herramienta dentro de Camel, en lugar de orquestarlo en la ruta

## Si algo no levanta

**Pod Pending.** `oc describe pod <nombre>` y la cuota: `oc get resourcequota compute-deploy`. Un workspace más el broker más una Integration entra en la cuota de referencia. Si hay otro Deployment tuyo, corré el Paso 0 o **Dev Spaces: Stop Workspace** desde la barra de estado antes de volver a entrar.

**Integration en Error.** `oc describe integration <nombre>` y los logs del pod. El primer síntoma suele estar en `status.conditions` y en el build. La referencia de fases está en [Running an Integration](https://camel.apache.org/camel-k/next/running/running.html).

**401 del modelo.** El token venció. Volvé a correr el Paso 4 o el 5. La tarea recrea el Secret con `oc whoami -t`.

**PKIX o hostname en el Paso 4 o 5.** El predictor no presentó la CA de `service-ca.crt`, o el nombre del certificado no coincide con el host del Service. El mensaje queda en el log de la Integration y en el cuerpo de `/ask`.

**Kaoto no aparece.** El registry embebido de Dev Spaces a veces no tiene `redhat.vscode-kaoto`. Instalá el VSIX desde [Open VSX](https://open-vsx.org/extension/redhat/vscode-kaoto). La lista de formatos que abre el editor está en la [documentación de Kaoto](https://kaoto.io/docs/).

**La Route no abre.** `oc get route`. El host es el de tu proyecto. Sumá el path (`/hello`, `/ask` o `/mcp`).

## Índice de documentación

Camel K

- [Running an Integration](https://camel.apache.org/camel-k/next/running/running.html)
- [Traits](https://camel.apache.org/camel-k/next/traits/traits.html)
- [container](https://camel.apache.org/camel-k/next/traits/container.html)
- [ingress](https://camel.apache.org/camel-k/next/traits/ingress.html)
- [builder](https://camel.apache.org/camel-k/next/traits/builder.html)
- [camel](https://camel.apache.org/camel-k/next/traits/camel.html) (properties y `runtimeVersion`)
- [environment](https://camel.apache.org/camel-k/next/traits/environment.html)
- [mount](https://camel.apache.org/camel-k/next/traits/mount.html)
- [API de Integration](https://camel.apache.org/camel-k/next/apis/camel-k.html)
- En el cluster: `oc explain integration.spec.traits`

Camel 4.8, la línea del catálogo de referencia

- [Índice de componentes](https://camel.apache.org/components/4.8.x/index.html)
- [YAML DSL](https://camel.apache.org/manual/yaml-dsl.html)
- [timer](https://camel.apache.org/components/4.8.x/timer-component.html)
- [log](https://camel.apache.org/components/4.8.x/log-component.html)
- [platform-http](https://camel.apache.org/components/4.8.x/platform-http-component.html)
- [direct](https://camel.apache.org/components/4.8.x/direct-component.html)
- [kafka](https://camel.apache.org/components/4.8.x/kafka-component.html)
- [http](https://camel.apache.org/components/4.8.x/http-component.html)
- [langchain4j-chat](https://camel.apache.org/components/4.8.x/langchain4j-chat-component.html)
- [langchain4j-tools](https://camel.apache.org/components/4.8.x/langchain4j-tools-component.html)
- [choice](https://camel.apache.org/components/4.8.x/eips/choice-eip.html)
- [JSON data format](https://camel.apache.org/components/4.8.x/dataformats/json-dataformat.html)

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
