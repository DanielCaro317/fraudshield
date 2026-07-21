# Manual 08 — Portar el copilot a GCP (multi-cloud)

> **Objetivo:** Portar el **mismo** sistema RAG de AWS a **Google Cloud** — no reconstruirlo desde cero, sino **mapearlo** servicio por servicio: S3→Cloud Storage, Bedrock/Claude→Vertex AI/Gemini, Knowledge Bases→**Vertex AI RAG Engine**, OpenSearch→**Vertex AI Vector Search 2.0**, Guardrails→**Model Armor**, Lambda→Cloud Run, CloudWatch→Cloud Logging. Al terminar tendrás **una sola arquitectura mental** que te deja explicar **Bedrock Y Vertex AI** con propiedad — el arma multi-cloud que piden las vacantes.
>
> **Por qué importa:** ~70% de clientes remotos usan AWS, pero GCP y Azure aparecen constantemente. Saber decir *"implementé el copilot en AWS y lo porté a GCP; aquí está la comparación Bedrock↔Vertex, Guardrails↔Model Armor"* demuestra que entiendes **arquitectura**, no solo un proveedor.
>
> **Tiempo estimado:** 3–4 horas (más rápido: ya construiste todo en AWS).
> **Requisitos:** Manuales AWS [02](./02_bedrock_kb_opensearch.md)–[07](./07_despliegue_produccion.md). Tu proyecto **[gcp-fraudshield](../../gcp-fraudshield/)** ya cubre GCP base (Cloud Storage, Vertex AI, RAG) — este manual lo **conecta** con el copilot.

---

## 📋 Tabla de contenido

1. [La tabla maestra de equivalencias](#1-equivalencias)
2. [Principio: portar, no reconstruir](#2-portar)
3. [Paso A — Almacenamiento y modelos](#3-storage-modelos)
4. [Paso B — RAG gestionado (Vertex AI RAG Engine)](#4-rag-engine)
5. [Paso C — Guardrails → Model Armor](#5-model-armor)
6. [Paso D — Despliegue e infra](#6-despliegue)
7. [Paso E — LangChain como capa portable](#7-langchain)
8. [La narrativa multi-cloud](#8-narrativa)
9. [✅ Checklist final](#9-checklist)
10. [📖 Glosario](#10-glosario)
11. [🔗 Fuentes (verificadas jul-2026)](#11-fuentes)

---

## 1. Equivalencias

**La tabla que debes saber de memoria.** Cada pieza de tu copilot AWS tiene su gemelo en GCP:

| Función | AWS (lo que construiste) | GCP (a dónde lo portas) |
|---|---|---|
| Almacenamiento (Data Lake) | **S3** | **Cloud Storage** |
| LLMs gestionados | **Bedrock** (Claude) | **Vertex AI** (Gemini) — *y Claude vía Model Garden* |
| Embeddings | Titan Embeddings | Vertex AI **text-embedding** |
| RAG gestionado | **Bedrock Knowledge Bases** | **Vertex AI RAG Engine** |
| Vector store | **OpenSearch Serverless / S3 Vectors** | **Vertex AI Vector Search 2.0** |
| Guardrails de IA | **Bedrock Guardrails** | **Model Armor** |
| Evaluación | **Bedrock Evaluations** | **Vertex AI Gen AI evaluation** |
| Cómputo serverless (API) | **Lambda** | **Cloud Run** / Cloud Functions |
| Puerta de API | **API Gateway** | **API Gateway** / Cloud Endpoints |
| Logs / métricas | **CloudWatch** | **Cloud Logging / Monitoring** |
| Secretos | **Secrets Manager** | **Secret Manager** |
| Permisos | **IAM** (Identity Center) | **Cloud IAM** |
| Observabilidad LLM | LangSmith | **Langfuse** (o LangSmith) |

💡 **Imprime esta tabla.** Es la respuesta directa a *"¿y esto en GCP cómo sería?"*.

---

## 2. Portar

📖 **La clave:** los **conceptos de RAG no cambian** (chunking, embeddings, retrieval, grounding, evaluación, guardrails). Lo que cambia son **nombres de servicios y firmas de API**. Portar = mapear, no reaprender.

Lo que **se queda igual:**
- Tu **golden set** y tus métricas (Manual 05) — la evaluación es agnóstica de nube.
- Tu **modelo de amenazas** (Manual 04) — OWASP LLM aplica igual.
- Tus **documentos** y su metadata.
- La **lógica**: recuperar → construir prompt → generar con grounding → citar → rechazar.

Lo que **cambia:**
- Los **SDKs** (`boto3` → `google-genai` / `google-cloud-*`).
- Los **servicios gestionados** (KB → RAG Engine, Guardrails → Model Armor).

---

## 3. Storage modelos

**Almacenamiento:** sube los mismos documentos a **Cloud Storage** (tu proyecto GCP ya lo hace):
```bash
gcloud storage cp ingestion/docs/* gs://<tu-bucket>/docs/
```
🔁 `aws s3 cp` → `gcloud storage cp`. Mismo concepto de Data Lake.

**Modelos (Gemini vía Vertex AI)** con el SDK unificado **`google-genai`** (el moderno; reemplaza al viejo `vertexai.generative_models`):
```python
# pip install google-genai
from google import genai
client = genai.Client(vertexai=True, project="<TU_PROJECT>", location="us-central1")

resp = client.models.generate_content(
    model="gemini-2.5-pro",
    contents="Responde en una frase: ¿qué es RAG?",
)
print(resp.text)
```
🔁 `bedrock.converse(...)` → `client.models.generate_content(...)`. **Es tu Converse, con otro SDK.**

💡 **Dato de oro:** **Claude también está en Vertex AI** (Model Garden). Podrías usar *el mismo modelo* en ambas nubes — un punto que impresiona: *"Bedrock y Vertex ofrecen Claude; elijo por integración, precio y región."*

### ✅ Checkpoint 3
Gemini te responde desde Vertex AI y subiste los documentos a Cloud Storage.

---

## 4. RAG Engine

📖 **Vertex AI RAG Engine** (GA): el **RAG gestionado** de GCP — el gemelo de Bedrock Knowledge Bases. Ingiere de Cloud Storage, hace chunking + embeddings, indexa en **Vertex AI Vector Search 2.0** (que ya trae **búsqueda híbrida + re-ranking semántico** integrados) y expone recuperación.

Flujo equivalente al Manual 02:
```
AWS:  S3 → Bedrock KB → OpenSearch → Retrieve/RetrieveAndGenerate
GCP:  Cloud Storage → Vertex AI RAG Engine → Vector Search 2.0 → retrieval + Gemini
```

💡 Tu proyecto **gcp-fraudshield** ya construye el RAG en Vertex AI (Manual 05 de ese proyecto). Aquí solo reconoces que **es el mismo patrón** que el copilot AWS, con documentos de políticas en vez de quejas.

🔁 **Vector Search 2.0** ≈ OpenSearch: ambos hacen vector + híbrida. La diferencia es el proveedor.

### ✅ Checkpoint 4
Entiendes cómo el pipeline de KB+OpenSearch se mapea 1:1 a RAG Engine + Vector Search.

---

## 5. Model Armor

📖 **Model Armor:** el equivalente de **Bedrock Guardrails** en GCP. Intercepta **prompts antes** de llegar a Gemini y **respuestas antes** de volver a tu app. Mapeo de tus 6 políticas del Manual 04:

| Bedrock Guardrails (Manual 04) | Model Armor |
|---|---|
| Content filters (Hate, Violence…) | **Responsible AI filters** (content harms) |
| **Prompt Attack** detection | **Prompt injection & jailbreak detection** |
| Denied topics | Filtros de contenido/políticas |
| Sensitive info / PII | **Sensitive Data Protection (SDP/DLP)** |
| — | **Malicious URL / malware detection** (extra de Model Armor) |
| Contextual grounding | Grounding/validación (Vertex safety + grounding) |

🔁 **La defensa en profundidad se mantiene:** IAM (Cloud IAM), secretos (Secret Manager), logging (Cloud Logging), rate limiting (API Gateway/Cloud Run) — mismos conceptos del Manual 04, otros nombres.

💬 **Frase de entrevista:** *"En AWS uso Bedrock Guardrails; en GCP, Model Armor. Ambos filtran prompt injection, jailbreaks, contenido dañino y datos sensibles sobre input y output. Model Armor añade detección de URLs maliciosas. La arquitectura de defensa en profundidad es idéntica."*

### ✅ Checkpoint 5
Sabes mapear cada política de Guardrails a Model Armor y qué añade cada uno.

---

## 6. Despliegue

🔁 **Lambda/API Gateway → Cloud Run.** Cloud Run es **aún más simple**: despliegas el **mismo contenedor** de tu FastAPI (el `Dockerfile` del Manual 07) sin adaptadores:
```bash
gcloud run deploy banking-copilot --source . --region us-central1 --allow-unauthenticated
```
- **Observabilidad:** Cloud Run manda logs/métricas a **Cloud Logging/Monitoring** automáticamente (≈ CloudWatch).
- **Secretos:** **Secret Manager** (≈ Secrets Manager).
- **IAM:** **Cloud IAM** con service accounts de mínimo privilegio (≈ IAM del Manual 07 §5).
- **CI/CD:** el mismo GitHub Actions; cambia el paso de deploy (`gcloud run deploy`) y usa **Workload Identity Federation** (el OIDC de GCP, ≈ el del Manual 07).

### ✅ Checkpoint 6
Tu contenedor corre en Cloud Run con una URL pública, logs en Cloud Logging. **Mismo servicio, otra nube.**

---

## 7. Langchain

📖 **El atajo de portabilidad:** si usaste **LangChain** (Manual 06), portar es casi **cambiar una línea** — el modelo:
```python
# AWS
from langchain_aws import ChatBedrockConverse
llm = ChatBedrockConverse(model="<claude>", region_name="us-east-1")

# GCP  (pip install langchain-google-vertexai)
from langchain_google_vertexai import ChatVertexAI
llm = ChatVertexAI(model="gemini-2.5-pro", project="<PROJECT>", location="us-central1")
```
**La cadena LCEL, el prompt, el retriever y las evals se quedan igual.** Ese es el argumento de portabilidad de LangChain que vendiste en el Manual 06 — aquí lo demuestras.

💬 **Frase de entrevista:** *"Con LangChain como capa de orquestación, portar de Bedrock a Vertex fue cambiar el componente del modelo; el resto de la cadena, prompts y evaluación se mantuvieron. Sin LangChain, reescribo las llamadas del SDK — más control, menos portabilidad. Elijo según el caso."*

### ✅ Checkpoint 7
Cambiaste `ChatBedrockConverse` por `ChatVertexAI` y tu cadena RAG corre en GCP con cambios mínimos.

---

## 8. Narrativa

Con este manual cierras **una sola historia** para cualquier entrevista, en cualquier nube:

> *"Construí un **Banking Policy Copilot**: un RAG de producción. Lo implementé **nativo en AWS** con boto3 (Bedrock Knowledge Bases, OpenSearch/S3 Vectors, Guardrails), lo evalué rigurosamente (golden set, RAGAS, Bedrock Evaluations), lo aseguré con defensa en profundidad (OWASP LLM, IAM mínimo, PII, contextual grounding), lo desplegué con IaC y CI/eval-gates, y lo **porté a GCP** (Vertex AI RAG Engine, Vector Search, Model Armor, Cloud Run) para demostrar portabilidad multi-cloud. Y tengo la versión LangChain para comparar orquestación."*

Eso cubre **RAG, Bedrock/Vertex, seguridad, evaluación, despliegue, LangChain y multi-cloud** — el perfil completo que persigues.

---

## 9. Checklist

- [ ] Memoricé la **tabla de equivalencias** AWS↔GCP.
- [ ] Entiendo que **porto, no reconstruyo** (conceptos iguales, SDKs distintos).
- [ ] Corrí **Gemini en Vertex AI** con `google-genai` y subí docs a Cloud Storage.
- [ ] Mapeo **Bedrock KB → Vertex AI RAG Engine** y **OpenSearch → Vector Search 2.0**.
- [ ] Mapeo **Guardrails → Model Armor** (las 6 políticas) y sé qué añade cada uno.
- [ ] Sé desplegar el **mismo contenedor** en **Cloud Run** con logging/IAM/secretos GCP.
- [ ] Demostré la **portabilidad de LangChain** (`ChatBedrockConverse`→`ChatVertexAI`).
- [ ] Puedo contar la **narrativa multi-cloud** completa en una frase.

Si marcaste todo: **dominas el copilot en dos nubes** y puedes defenderlo ante cualquier stack. 🎉 **Completaste la serie AWS del Banking Policy Copilot.**

---

## 10. Glosario

- **Cloud Storage:** almacenamiento de objetos de GCP (≈ S3).
- **Vertex AI:** plataforma de IA/LLMs de GCP (≈ Bedrock).
- **Gemini:** familia de LLMs de Google (≈ Claude en Bedrock).
- **Vertex AI RAG Engine:** RAG gestionado de GCP (≈ Bedrock KB).
- **Vertex AI Vector Search 2.0:** vector store gestionado con híbrida/re-ranking (≈ OpenSearch).
- **Model Armor:** guardrails de GCP (≈ Bedrock Guardrails).
- **Cloud Run:** contenedores serverless (≈ Lambda + API Gateway).
- **Cloud Logging/Monitoring:** observabilidad (≈ CloudWatch).
- **Workload Identity Federation:** OIDC de GCP para CI sin llaves (≈ el OIDC AWS).
- **google-genai:** SDK unificado de Google para Gemini/Vertex.

---

## 11. Fuentes

Verificadas el **21 de julio de 2026**:

- Vertex AI RAG Engine (GA) — [cloud.google.com/blog/products/ai-machine-learning/introducing-vertex-ai-rag-engine](https://cloud.google.com/blog/products/ai-machine-learning/introducing-vertex-ai-rag-engine)
- Vertex AI Vector Search (RAG) — [docs.cloud.google.com/vertex-ai/generative-ai/docs/rag-engine/use-rag-managed-vertex-ai-vector-search](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/rag-engine/use-rag-managed-vertex-ai-vector-search)
- Model Armor — [cloud.google.com/security/products/model-armor](https://cloud.google.com/security/products/model-armor) · [cloud.google.com/blog/products/identity-security/how-model-armor-can-help-protect-your-ai-apps](https://cloud.google.com/blog/products/identity-security/how-model-armor-can-help-protect-your-ai-apps)
- SDK `google-genai` (Gemini en Vertex) — [docs.cloud.google.com/vertex-ai/generative-ai/docs/start/quickstarts/quickstart](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/start/quickstarts/quickstart)
- LangChain Vertex AI — [python.langchain.com/docs/integrations/chat/google_vertex_ai_palm/](https://python.langchain.com/docs/integrations/chat/google_vertex_ai_palm/)

---

> 🎉 **Serie AWS completa.** Tienes el **Banking Policy Copilot** de punta a punta: RAG entendido a fondo, Bedrock nativo, Guardrails, evaluación, LangChain, despliegue de producción y portabilidad a GCP. Junto con **[gcp-fraudshield](../../gcp-fraudshield/)** (data + ML), cubres el perfil completo: **AI Engineer de producción + Data/ML Engineer**, en dos nubes, con una sola narrativa demostrable.
