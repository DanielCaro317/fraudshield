# Manual 07 — Despliegue en producción (API + IaC + CI/CD)

> **Objetivo:** Convertir tu copilot de "script en un notebook" a **servicio de producción**: una **API** (`API Gateway → Lambda → Bedrock/KB`) con **IAM de mínimo privilegio**, **infraestructura como código** (CDK o Terraform), **observabilidad** (CloudWatch), **manejo de errores/timeouts/retries**, **streaming** de respuestas, y **CI/CD con eval-gates** (GitHub Actions que corre las evals del Manual 05 y **bloquea el merge** si baja la calidad). Aterrizas también el vocabulario **DevOps vs MLOps vs LLMOps**.
>
> **Por qué te diferencia:** en tu entrevista, CI/CD y despliegue sonaron confusos ("algo con GitHub Actions... envelopes..."). Aquí construyes un pipeline **real** y aprendes a describirlo con precisión.
>
> **Tiempo estimado:** 4–5 horas.
> **Requisitos:** Manuales [03](./03_retrieve_generate_boto3.md) (RAG), [04](./04_guardrails_seguridad.md) (Guardrails) y [05](./05_evaluacion_dataset.md) (evals para el gate).

> ⚠️ **Costo:** Lambda y API Gateway tienen free tier generoso; Bedrock se paga por token. Si usaste OpenSearch, míralo (Manual 02 §11). Pon un **budget** (Manual 00 §5).

---

## 📋 Tabla de contenido

1. [Arquitectura de despliegue](#1-arquitectura)
2. [DevOps vs MLOps vs LLMOps](#2-vocabulario)
3. [Paso A — La API (FastAPI, local primero)](#3-api)
4. [Paso B — Empaquetar para Lambda](#4-lambda)
5. [Paso C — IAM de mínimo privilegio](#5-iam)
6. [Paso D — Infraestructura como código (CDK/Terraform)](#6-iac)
7. [Paso E — Observabilidad (CloudWatch, logging, costo)](#7-observabilidad)
8. [Paso F — Streaming de respuestas](#8-streaming)
9. [Paso G — Errores, timeouts y retries](#9-errores)
10. [Paso H — CI/CD con eval-gates (GitHub Actions)](#10-cicd)
11. [Entregables del repo (runbook + costos)](#11-entregables)
12. [✅ Checklist final](#12-checklist)
13. [🛟 Solución de problemas](#13-troubleshooting)
14. [📖 Glosario](#14-glosario)
15. [🔗 Fuentes (verificadas jul-2026)](#15-fuentes)

---

## 1. Arquitectura

```
Cliente (web / curl)
   │  HTTPS
   ▼
API Gateway ──(auth, rate limiting, timeout)──► AWS Lambda (tu código RAG)
                                                   │
                                                   ├─► Guardrail (ApplyGuardrail: input)
                                                   ├─► Bedrock KB (Retrieve)  [OpenSearch/S3 Vectors]
                                                   ├─► Bedrock (Converse / ConverseStream)
                                                   └─► Guardrail (ApplyGuardrail: output)
                                                   │
                                                   ▼
                                          CloudWatch (logs, métricas, alarmas)
Secrets Manager (claves)   ·   IAM (mínimo privilegio)   ·   Budgets (costo)
```

Todo lo que construiste en los manuales anteriores se **ensambla** aquí detrás de una API real.

---

## 2. Vocabulario

Define los tres términos (los mezclaste en la entrevista — ahora con precisión):

| Término | Qué cubre | En tu proyecto |
|---|---|---|
| **DevOps** | Ciclo de vida del **software/infra**: build, test, deploy, monitoreo | GitHub Actions, IaC, CloudWatch |
| **MLOps** | Ciclo de vida del **modelo ML**: datos, entrenamiento, registro, versionado, drift | (más en el proyecto GCP: modelo de fraude) |
| **LLMOps** | Ciclo de vida de apps **LLM**: prompts versionados, **evals**, **guardrails**, tracing, costo/tokens | Manuales 04–06 + eval-gates de este |

💬 **Frase de entrevista:** *"DevOps es el ciclo del software; MLOps el del modelo; LLMOps añade lo propio de LLMs: versionado de prompts, evaluación continua, guardrails, tracing y control de costo/tokens. Mi pipeline los combina."*

---

## 3. API

Desarrolla la API con **FastAPI** local (rápido de iterar). El handler **reusa** tu pipeline seguro de los Manuales 03–04:

`api/main.py`
```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import boto3
from botocore.config import Config

REGION = "us-east-1"
KB_ID, MODEL_ID, GID, GV = "<KB_ID>", "<MODEL_ID>", "<GUARDRAIL_ID>", "DRAFT"

cfg = Config(retries={"max_attempts": 3, "mode": "adaptive"}, read_timeout=30)
agent = boto3.client("bedrock-agent-runtime", region_name=REGION, config=cfg)
brt = boto3.client("bedrock-runtime", region_name=REGION, config=cfg)

app = FastAPI(title="Banking Policy Copilot")

class Query(BaseModel):
    question: str

def guard(text, source):
    r = brt.apply_guardrail(guardrailIdentifier=GID, guardrailVersion=GV,
                            source=source, content=[{"text": {"text": text}}])
    return r["action"] == "GUARDRAIL_INTERVENED"

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/ask")
def ask(q: Query):
    if guard(q.question, "INPUT"):
        raise HTTPException(400, "Consulta bloqueada por política de seguridad.")
    res = agent.retrieve(knowledgeBaseId=KB_ID, retrievalQuery={"text": q.question},
                         retrievalConfiguration={"vectorSearchConfiguration": {"numberOfResults": 4}})
    chunks = [r for r in res["retrievalResults"] if r["score"] >= 0.4]
    if not chunks:
        return {"answer": "No encuentro esa información en las políticas disponibles.", "sources": []}
    contexto = "\n\n".join(c["content"]["text"] for c in chunks)
    prompt = f"Responde solo con el contexto y cita la fuente.\n\n{contexto}\n\nPregunta: {q.question}"
    out = brt.converse(modelId=MODEL_ID,
                       messages=[{"role": "user", "content": [{"text": prompt}]}],
                       inferenceConfig={"temperature": 0.0, "maxTokens": 500})
    answer = out["output"]["message"]["content"][0]["text"]
    return {"answer": answer,
            "sources": [c["location"].get("s3Location", {}).get("uri") for c in chunks]}
```

Pruébalo local:
```bash
pip install "fastapi[standard]" uvicorn boto3
uvicorn api.main:app --reload
# en otra terminal:
curl -X POST localhost:8000/ask -H "Content-Type: application/json" \
     -d '{"question":"¿Plazo para resolver un reclamo de fraude?"}'
```

### ✅ Checkpoint 3
La API responde local con respuesta + fuentes, y **bloquea** consultas maliciosas. Tienes el servicio; falta llevarlo a la nube.

---

## 4. Lambda

📖 **Lambda:** ejecuta tu código **sin servidores**, pagando por invocación. Dos formas de llevar FastAPI:

- **(Recomendada) Imagen de contenedor + AWS Lambda Web Adapter:** empaquetas tu FastAPI tal cual en una imagen; el adapter la expone como Lambda. Cero cambios al código.
- **Handler nativo:** reescribes como `def handler(event, context)`. Menos dependencias, pero pierdes FastAPI.

`Dockerfile` (con Lambda Web Adapter):
```dockerfile
FROM public.ecr.aws/lambda/python:3.12
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.9.0 /lambda-adapter /opt/extensions/lambda-adapter
ENV PORT=8000 AWS_LWA_INVOKE_MODE=RESPONSE_STREAM
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY api/ ./api/
CMD ["python","-m","uvicorn","api.main:app","--host","0.0.0.0","--port","8000"]
```

⌨️ Construir y publicar la imagen a **ECR** (Elastic Container Registry) — lo hará tu IaC/CI (§6, §10).

### ✅ Checkpoint 4
Tienes un `Dockerfile` que empaqueta tu API para Lambda. (El despliegue real lo hace la IaC.)

🔁 **GCP:** el equivalente de este empaquetado serverless es **Cloud Run** (contenedor directo, aún más simple).

---

## 5. IAM

Ahora sí aplicas el **mínimo privilegio** que prometiste en el Manual 04. El rol de la Lambda solo puede lo que necesita — **nada de `*`**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {"Effect": "Allow", "Action": ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"],
     "Resource": "arn:aws:bedrock:us-east-1::foundation-model/*"},
    {"Effect": "Allow", "Action": ["bedrock:Retrieve"],
     "Resource": "arn:aws:bedrock:us-east-1:<ACCOUNT_ID>:knowledge-base/<KB_ID>"},
    {"Effect": "Allow", "Action": ["bedrock:ApplyGuardrail"],
     "Resource": "arn:aws:bedrock:us-east-1:<ACCOUNT_ID>:guardrail/<GUARDRAIL_ID>"}
  ]
}
```

💬 **Frase de entrevista:** *"El rol de la función solo puede invocar el modelo, recuperar de esa KB específica y aplicar ese guardrail — sobre recursos concretos, no comodines. Principio de mínimo privilegio."*

---

## 6. IaC

📖 **Infraestructura como código (IaC):** definir la infra en **código versionado** (no clics), para que sea **reproducible** y revisable. Dos opciones:

- **AWS CDK** (Python) — código imperativo, ideal si ya sabes Python.
- **Terraform** — declarativo, multi-cloud (útil para tu narrativa AWS+GCP).

Esqueleto con **CDK (Python)** — provisiona Lambda + API Gateway + rol:
```python
# infra/app.py  (aws-cdk-lib v2)
from aws_cdk import App, Stack, Duration
from aws_cdk import aws_lambda as _lambda, aws_apigateway as apigw, aws_iam as iam
from constructs import Construct

class CopilotStack(Stack):
    def __init__(self, scope: Construct, id: str, **kw):
        super().__init__(scope, id, **kw)
        fn = _lambda.DockerImageFunction(self, "CopilotFn",
            code=_lambda.DockerImageCode.from_image_asset("."),
            timeout=Duration.seconds(60), memory_size=1024)
        # mínimo privilegio (ver §5)
        fn.add_to_role_policy(iam.PolicyStatement(
            actions=["bedrock:InvokeModel", "bedrock:Retrieve", "bedrock:ApplyGuardrail"],
            resources=["*"]))  # afínalo a los ARNs concretos
        apigw.LambdaRestApi(self, "CopilotApi", handler=fn)

app = App(); CopilotStack(app, "BankingCopilot"); app.synth()
```
```bash
npm install -g aws-cdk        # una vez
cdk bootstrap                 # una vez por cuenta/región
cdk deploy                    # crea/actualiza toda la infra
```

### ✅ Checkpoint 6
`cdk deploy` crea la Lambda + API Gateway y te devuelve una **URL**. Llámala con `curl`. **Tu copilot vive en la nube, definido por código.**

🛟 *`cdk` requiere Node.js.* Instálalo si no lo tienes. Alternativa sin Node: **Terraform**.

---

## 7. Observabilidad

- **Logs:** Lambda escribe a **CloudWatch Logs** automáticamente. Añade `print`/`logging` con el `question`, latencia y si intervino el guardrail (sin loggear PII).
- **Métricas y alarmas:** CloudWatch trae invocaciones, errores, duración. Crea una **alarma** si errores > X o duración p95 sube.
- **Model invocation logging:** activa el registro de prompts/respuestas de Bedrock a CloudWatch/S3 (Manual 04 §10) para auditoría.
- **Costo:** etiqueta recursos y revisa **Cost Explorer**; la alarma de **Budgets** ya avisa.

### ✅ Checkpoint 7
Ves los logs de tus invocaciones en CloudWatch y tienes al menos una **alarma**. Sin observabilidad no hay operación profesional.

---

## 8. Streaming

📖 **Streaming:** enviar la respuesta **token a token** (mejor UX en chat). En banca/producción importa la **percepción de rapidez** (time-to-first-token).

- Genera con **`ConverseStream`** (en vez de `Converse`): boto3 devuelve un stream de eventos.
- Entrégalo al cliente con **Lambda response streaming**:
  - **Lambda Function URL** con response streaming (lo más simple), o
  - **API Gateway REST con response streaming** (soportado desde nov-2025).

```python
# Generación en streaming con Bedrock
stream = brt.converse_stream(modelId=MODEL_ID,
    messages=[{"role": "user", "content": [{"text": prompt}]}])
for event in stream["stream"]:
    if "contentBlockDelta" in event:
        print(event["contentBlockDelta"]["delta"]["text"], end="", flush=True)
```

⚠️ **El truco (pregunta de entrevista):** el API Gateway clásico tiene **timeout de integración de 29s** — mata respuestas largas. Para streaming usa **Function URL con response streaming** o **API Gateway con response streaming** (idle timeout de 5 min en regional). No lo dejes en modo buffer.

### ✅ Checkpoint 8
Ves la respuesta aparecer **token a token**. Sabes explicar por qué el API Gateway clásico no basta para streaming largo.

---

## 9. Errores

Producción = asumir que **todo falla**. Controla:

- **Retries con backoff:** ya lo pusiste en boto3 (`Config(retries={"mode": "adaptive"})`). Reintenta throttling/errores transitorios de Bedrock.
- **Timeouts:** `read_timeout` en boto3, `timeout` en Lambda (60s), coherentes entre capas.
- **ThrottlingException de Bedrock:** captura y responde 429 con mensaje claro; considera **cuotas** y **provisioned throughput** si el volumen crece.
- **Degradación elegante:** si Bedrock falla, responde un mensaje útil, no un stack trace.
- **Idempotencia y validación de entrada:** valida el payload (Pydantic ya ayuda).

### ✅ Checkpoint 9
Tu API maneja un throttling simulado sin caerse (responde 429 controlado). Robusta, no frágil.

---

## 10. CI/CD

📖 **CI/CD con eval-gates:** en cada Pull Request, GitHub Actions corre **lint + tests + evals** y **bloquea el merge si la calidad baja**. Es lo que separa "subo código y rezo" de un pipeline profesional.

`.github/workflows/ci.yml`
```yaml
name: CI
on: [pull_request]
permissions:
  id-token: write        # para OIDC → asumir rol AWS SIN llaves de larga duración
  contents: read
jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - run: pip install -r requirements.txt ruff pytest
      - name: Lint
        run: ruff check .
      - name: Configurar credenciales AWS (OIDC, sin secretos)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::<ACCOUNT_ID>:role/github-ci
          aws-region: us-east-1
      - name: Tests
        run: pytest -q
      - name: Eval-gate (bloquea si la calidad baja)
        run: python eval/run_eval_gate.py   # sale con código ≠0 si faithfulness < umbral
```

`eval/run_eval_gate.py` (idea):
```python
import sys
from mi_eval import evaluar   # reusa el Manual 05
score = evaluar()             # ej. faithfulness medio sobre un mini golden set
UMBRAL = 0.80
print(f"faithfulness={score:.2f} (umbral {UMBRAL})")
sys.exit(0 if score >= UMBRAL else 1)   # ≠0 → falla el merge
```

**CD:** en push a `main`, otro workflow hace `cdk deploy` (o build+push a ECR) con el rol OIDC. **Versiona prompts y guardrails** junto al código.

💡 **OIDC en vez de access keys:** GitHub asume un **rol IAM** temporalmente — coherente con el Manual 00 (nada de llaves de larga duración en secretos del repo).

### ✅ Checkpoint 10
Un PR que **empeora** la calidad (baja faithfulness) **falla el check** y no se puede mergear. *Eso* es un eval-gate. 

💬 **Frase de entrevista:** *"En cada PR corro ruff → pytest → evals (RAGAS/Bedrock) como eval-gate: si faithfulness o context recall bajan del umbral, el pipeline falla y bloquea el merge. En main, CD despliega con CDK usando OIDC, sin llaves de larga duración."*

---

## 11. Entregables

Tu repo debe incluir (lo que un reclutador senior busca):

- [ ] **Diagrama de arquitectura** (§1).
- [ ] **Código de infraestructura** (CDK/Terraform).
- [ ] **Código de ingesta** (Manual 02) y **de consulta** (API).
- [ ] **Dataset de evaluación** + **resultados antes/después** (Manual 05).
- [ ] **Threat model** (Manual 04 §11).
- [ ] **Estimación de costos** (Bedrock por token + vector store + Lambda/API GW).
- [ ] **Runbook de incidentes:** qué hacer si sube la latencia, si Bedrock throttlea, si el guardrail bloquea de más, si sube el costo. (1 página, pasos concretos.)
- [ ] **README con decisiones y trade-offs** (por qué S3 Vectors vs OpenSearch, por qué boto3 vs LangChain, etc.).

---

## 12. Checklist

- [ ] Tengo la **API** (FastAPI) funcionando local con Guardrails.
- [ ] La empaqueté para **Lambda** (contenedor + Web Adapter).
- [ ] Definí un rol IAM de **mínimo privilegio**.
- [ ] Desplegué con **IaC** (CDK/Terraform) y obtuve una URL.
- [ ] Tengo **logs + alarmas** en CloudWatch y **model invocation logging**.
- [ ] Implementé **streaming** y sé el truco del timeout de API Gateway.
- [ ] Manejo **errores/timeouts/retries** (throttling → 429).
- [ ] Tengo **CI con eval-gate** que bloquea el merge si baja la calidad.
- [ ] Uso **OIDC** (sin llaves de larga duración) en el CI.
- [ ] Distingo **DevOps / MLOps / LLMOps**.
- [ ] Mi repo tiene los **entregables** (diagrama, IaC, costos, runbook, README).

Si marcaste todo: tienes un **sistema RAG de producción en AWS**, seguro, evaluado, desplegado y observado. El Manual 08 lo **porta a GCP** para cerrar la narrativa multi-cloud.

---

## 13. Troubleshooting

| Síntoma | Causa | Solución |
|---|---|---|
| API Gateway corta a los 29s | Timeout de integración clásico | Usa Function URL / API GW con **response streaming** |
| `AccessDenied` en Lambda | Rol sin permiso de Bedrock/KB | Añade las acciones del §5 a los ARNs correctos |
| `cdk deploy` falla en bootstrap | Falta `cdk bootstrap` o Node | Bootstrapea; instala Node/CDK |
| `ThrottlingException` | Cuota de Bedrock | Retries adaptativos; sube cuota / provisioned throughput |
| CI no puede asumir rol | OIDC mal configurado | Crea el rol `github-ci` con trust a GitHub OIDC |
| Eval-gate siempre pasa | No hay umbral real | Asegura `sys.exit(1)` bajo umbral y un golden set mínimo |

---

## 14. Glosario

- **Lambda:** cómputo serverless por invocación.
- **API Gateway:** puerta HTTP gestionada (auth, rate limiting, timeouts).
- **Function URL:** endpoint HTTP directo de una Lambda (soporta response streaming).
- **ConverseStream:** API de Bedrock que devuelve la respuesta en streaming.
- **IaC / CDK / Terraform:** infraestructura como código.
- **CloudWatch:** logs, métricas y alarmas.
- **OIDC:** federación para que GitHub asuma un rol IAM temporal (sin llaves).
- **Eval-gate:** check de CI que bloquea el merge si la calidad baja.
- **DevOps / MLOps / LLMOps:** ciclos de vida de software / modelo / app LLM.
- **Runbook:** guía de pasos ante incidentes.

---

## 15. Fuentes

Verificadas el **21 de julio de 2026**:

- Estrategias serverless para streaming de LLM — [aws.amazon.com/blogs/compute/serverless-strategies-for-streaming-llm-responses/](https://aws.amazon.com/blogs/compute/serverless-strategies-for-streaming-llm-responses/)
- Lambda response streaming — [docs.aws.amazon.com/lambda/latest/dg/configuration-response-streaming.html](https://docs.aws.amazon.com/lambda/latest/dg/configuration-response-streaming.html)
- API Gateway response streaming (REST) — [aws.amazon.com/about-aws/whats-new/2025/11/api-gateway-response-streaming-rest-apis/](https://aws.amazon.com/about-aws/whats-new/2025/11/api-gateway-response-streaming-rest-apis/)
- Bedrock `ConverseStream` — [docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_ConverseStream.html](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_ConverseStream.html)
- AWS CDK (v2) — [docs.aws.amazon.com/cdk/v2/guide/home.html](https://docs.aws.amazon.com/cdk/v2/guide/home.html)
- GitHub OIDC con AWS — [docs.github.com/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)

---

> **➡️ Siguiente manual:** `08_portabilidad_a_gcp.md` — portar el **mismo** sistema a GCP para cerrar tu narrativa multi-cloud: S3→Cloud Storage, Bedrock→Vertex AI/Gemini, KB→Vertex AI RAG Engine, OpenSearch→Vertex AI Vector Search, Guardrails→**Model Armor**, Lambda→Cloud Run, CloudWatch→Cloud Logging. Una sola arquitectura mental para explicar Bedrock **y** Vertex AI.
