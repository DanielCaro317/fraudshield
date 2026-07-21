# Manual 06 — LangChain sobre Bedrock (comparar con el nativo)

> **Objetivo:** Reimplementar el **mismo** RAG que ya construiste con boto3, ahora con **LangChain sobre Bedrock** (`ChatBedrockConverse`, `BedrockEmbeddings`, `AmazonKnowledgeBasesRetriever`, cadenas con **LCEL**), y **compararlos** en velocidad de desarrollo, portabilidad, trazabilidad y complejidad. Tu repo tendrá **dos ramas**: `/native` (boto3) y `/langchain`. Y aprenderás **observabilidad** con **LangSmith**.
>
> **Por qué en este orden (no antes):** tu diagnóstico es claro — *"no empieces por LangChain, porque corres el riesgo de aprender nombres de clases sin comprender la arquitectura."* Ya entiendes RAG a mano y Bedrock nativo; **ahora** LangChain es una herramienta que dominas, no una caja negra. El discurso ganador: *"primero implementé con Boto3 para controlar cada componente, después con LangChain para comparar velocidad, observabilidad y portabilidad."*
>
> **Tiempo estimado:** 2–3 horas.
> **Requisitos:** [Manual 02](./02_bedrock_kb_opensearch.md) (KB creada) y [Manual 03](./03_retrieve_generate_boto3.md) (RAG nativo).

---

## 🖱️ / ⌨️ Cómo leer este manual

Todo código (LangChain vive en Python). Trabaja en `langchain/` y compara mentalmente cada bloque con su equivalente boto3 del Manual 03.

---

## 📋 Tabla de contenido

1. [Qué es LangChain (y qué NO)](#1-que-es)
2. [Setup](#2-setup)
3. [Paso A — Componentes Bedrock en LangChain](#3-componentes)
4. [Paso B — Retriever de Knowledge Bases](#4-retriever)
5. [Paso C — Cadena RAG con LCEL](#5-lcel)
6. [Paso D — Guardrails en la cadena](#6-guardrails)
7. [Paso E — Observabilidad con LangSmith](#7-langsmith)
8. [Nativo vs LangChain: la comparación](#8-comparacion)
9. [Estructura de ramas /native y /langchain](#9-ramas)
10. [✅ Checklist final](#10-checklist)
11. [🛟 Solución de problemas](#11-troubleshooting)
12. [📖 Glosario](#12-glosario)
13. [🔗 Fuentes (verificadas jul-2026)](#13-fuentes)

---

## 1. Que es

📖 **LangChain:** una librería de **orquestación** de aplicaciones LLM. No es "otra forma de hacer RAG separada de AWS" — **trabaja encima** de Bedrock, OpenSearch, etc. Te da componentes listos (modelos, embeddings, retrievers) y una forma de **encadenarlos**.

📖 **LCEL (LangChain Expression Language):** la forma **moderna** de construir cadenas, con el operador **pipe `|`**: `retriever | prompt | llm | parser`. Cada pieza es un *Runnable* (invocable, con streaming y async gratis).

> ⚠️ **Evita lo deprecado.** El estilo viejo `LLMChain`, `RetrievalQA` y `ChatBedrock` (API `invoke_model`) está siendo reemplazado. Usa **`ChatBedrockConverse`** (basado en la Converse API) y **LCEL**. Si un tutorial usa `LLMChain(...)`, es antiguo.

💡 **La pregunta que te harán:** *"¿por qué usar LangChain si ya sabes boto3?"* → *"Por velocidad de desarrollo, componentes reutilizables, portabilidad entre proveedores y trazabilidad con LangSmith. Pero no lo necesito para RAG en Bedrock; lo uso cuando su abstracción, integración o trazabilidad compensan la complejidad extra."*

---

## 2. Setup

```bash
cd aws-banking-copilot
source .venv/bin/activate
pip install langchain langchain-aws langchain-community
export AWS_PROFILE=copilot
```
- `langchain-aws` → integraciones oficiales de AWS (Bedrock, KB).
- `langchain` / `langchain-core` → LCEL, prompts, parsers.

---

## 3. Componentes

Los mismos modelos del Manual 01/03, ahora como objetos LangChain:

```python
from langchain_aws import ChatBedrockConverse, BedrockEmbeddings

REGION = "us-east-1"
llm = ChatBedrockConverse(
    model="<MODEL_ID_CLAUDE>",     # el del Playground (Manual 00)
    region_name=REGION,
    temperature=0,
    max_tokens=500,
)
embeddings = BedrockEmbeddings(
    model_id="amazon.titan-embed-text-v2:0",
    region_name=REGION,
)

print(llm.invoke("Responde en una frase: ¿qué es RAG?").content)
```

### ✅ Checkpoint 3
`llm.invoke(...)` devuelve una respuesta. **`ChatBedrockConverse` es tu `converse` del Manual 01, envuelto.** Mismo Bedrock por debajo.

---

## 4. Retriever

En vez de llamar a `agent.retrieve(...)` tú mismo (Manual 03), LangChain te da un **retriever** que apunta a tu Knowledge Base:

```python
from langchain_aws import AmazonKnowledgeBasesRetriever

retriever = AmazonKnowledgeBasesRetriever(
    knowledge_base_id="<TU_KB_ID>",
    retrieval_config={"vectorSearchConfiguration": {
        "numberOfResults": 4,
        # mismos filtros por metadata del Manual 03:
        # "filter": {"equals": {"key": "pais", "value": "CO"}},
    }},
)

docs = retriever.invoke("¿Plazo para resolver un reclamo de fraude?")
for d in docs:
    print(d.metadata.get("location"), "→", d.page_content[:80], "...")
```

### ✅ Checkpoint 4
El retriever devuelve `Document`s con `page_content` y `metadata`. **Es tu `Retrieve` del Manual 03**, pero como componente encadenable. Nota que `numberOfResults`, filtros, etc. son **los mismos parámetros** — porque por debajo es la misma API.

---

## 5. LCEL

Ahora **encadenamos** retriever + prompt + modelo + parser con LCEL. Compáralo con tu función `answer()` del Manual 03: hace lo mismo, en menos líneas.

```python
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough

prompt = ChatPromptTemplate.from_template(
    "Eres un asistente de políticas de un banco. Responde USANDO SOLO el contexto. "
    "Cita la fuente. Si no está, di 'No encuentro esa información en las políticas disponibles.'\n\n"
    "Contexto:\n{context}\n\nPregunta: {input}\n\nRespuesta:"
)

def format_docs(docs):
    return "\n\n".join(f"[{d.metadata.get('location','?')}] {d.page_content}" for d in docs)

rag_chain = (
    {"context": retriever | format_docs, "input": RunnablePassthrough()}
    | prompt
    | llm
    | StrOutputParser()
)

print(rag_chain.invoke("¿Qué verifico en una transferencia internacional grande?"))
```

💡 **Alternativa con helpers** (equivalente, más declarativo):
```python
from langchain.chains import create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain

combine = create_stuff_documents_chain(llm, prompt)     # el prompt usa {context}
rag = create_retrieval_chain(retriever, combine)
resp = rag.invoke({"input": "¿Plazo de un reclamo?"})
print(resp["answer"])          # respuesta
print(resp["context"])         # documentos usados (para citar)
```

### ✅ Checkpoint 5
La cadena responde con base en la KB. **En ~15 líneas tienes lo que en boto3 te tomó más.** Ese es el argumento "velocidad de desarrollo" de LangChain.

---

## 6. Guardrails

La seguridad del Manual 04 **no se pierde** con LangChain. Dos formas:

**a) `ApplyGuardrail` como paso de la cadena** (100% control, reusa lo del Manual 04):
```python
import boto3
from langchain_core.runnables import RunnableLambda
brt = boto3.client("bedrock-runtime", region_name=REGION)
GID, GV = "<TU_GUARDRAIL_ID>", "DRAFT"

def guard_input(question: str) -> str:
    r = brt.apply_guardrail(guardrailIdentifier=GID, guardrailVersion=GV,
                            source="INPUT", content=[{"text": {"text": question}}])
    if r["action"] == "GUARDRAIL_INTERVENED":
        raise ValueError("Entrada bloqueada por guardrail")
    return question

safe_chain = RunnableLambda(guard_input) | rag_chain
```

**b) Guardrail nativo en el modelo:** `ChatBedrockConverse` acepta configuración de guardrail (parámetro `guardrail_config`). Verifica el nombre exacto del kwarg en la doc de `langchain-aws` de tu versión, ya que evoluciona.

### ✅ Checkpoint 6
Una entrada maliciosa levanta el bloqueo antes de llegar al modelo. **Guardrails + LangChain conviven.**

---

## 7. LangSmith

📖 **LangSmith:** la plataforma de **observabilidad/tracing** de LangChain. Traza cada paso de la cadena (retriever, prompt, modelo), con prompts, respuestas, **tokens, latencia y costo** — invaluable para depurar y evaluar.

```bash
export LANGSMITH_TRACING=true
export LANGSMITH_API_KEY="<tu_api_key_de_langsmith>"
export LANGSMITH_PROJECT="banking-copilot"
```
Con esas variables, **cada `.invoke()` se traza automáticamente**. Entra a smith.langchain.com y verás el árbol de la cadena, cuánto tardó cada paso y cuántos tokens usó.

💡 **Alternativa open-source:** **Langfuse** (self-host, sin atarte a LangChain). Mismo concepto de tracing. En el proyecto GCP usarás Langfuse; aquí LangSmith — así conoces ambos.

### ✅ Checkpoint 7
Ves una traza de tu cadena RAG en LangSmith con latencia y tokens por paso. **Eso es observabilidad de LLM** — otra respuesta que en tu entrevista quedó floja y ahora sostienes.

💬 **Frase de entrevista:** *"Instrumento con LangSmith o Langfuse para trazar cadenas y agentes: veo prompts, respuestas, tokens, latencia y costo por paso, y conecto las trazas con mis evals para un feedback loop de calidad."*

---

## 8. Comparacion

La tabla que justifica **cuándo** usar cada uno (memorízala):

| Criterio | boto3 nativo (`/native`) | LangChain (`/langchain`) |
|---|---|---|
| Velocidad de desarrollo | Más lento | **Más rápido** (componentes listos) |
| Control fino | **Total** | Alto, pero con capas de abstracción |
| Curva / dependencias | Mínimas | Más librerías, cambios de API frecuentes |
| Portabilidad entre proveedores | Tú la programas | **Alta** (cambias el modelo, no la cadena) |
| Observabilidad | Tú la montas | **LangSmith integrado** |
| Riesgo de "magia" no entendida | Bajo | Alto si no entiendes debajo |
| Ideal para | Producción con requisitos finos, latencia | Prototipar rápido, multi-proveedor, agentes |

💬 **La frase completa:** *"No necesito LangChain para implementar RAG en Bedrock. Lo uso cuando su abstracción, integración, trazabilidad o portabilidad compensan la complejidad adicional. Para control fino y latencia, boto3 nativo; para iterar rápido y observar, LangChain."*

---

## 9. Ramas

Tu repo debe **mostrar ambas** implementaciones — es lo que impresiona en una entrevista:

```
aws-banking-copilot/
├── retrieval/         → /native : boto3 + Bedrock + KB   (Manuales 01-03)
└── langchain/         → /langchain : LangChain + Bedrock + KB  (este manual)
```

💬 *"Primero implementé el flujo directamente con Boto3 para comprender y controlar cada componente. Después construí una segunda implementación con LangChain para comparar velocidad de desarrollo, observabilidad, portabilidad y complejidad."* — demuestra **mucho más** conocimiento que solo un tutorial de LangChain.

🔁 **GCP:** los mismos componentes de LangChain apuntan a **Vertex AI / Gemini** cambiando el modelo (`ChatVertexAI`) — esa es la portabilidad que venderás en el Manual 08.

---

## 10. Checklist

- [ ] Entiendo qué es LangChain y **por qué no empezar por él**.
- [ ] Uso **`ChatBedrockConverse`** y **`BedrockEmbeddings`** (no los deprecados).
- [ ] Uso **`AmazonKnowledgeBasesRetriever`** sobre mi KB.
- [ ] Construí una **cadena RAG con LCEL** (`|`) y con helpers.
- [ ] Integré **Guardrails** en la cadena.
- [ ] Instrumenté con **LangSmith** (o conozco Langfuse) y vi una traza.
- [ ] Tengo la **tabla de comparación** nativo vs LangChain y sé cuándo usar cada uno.
- [ ] Mi repo tiene las dos ramas/carpetas `/native` y `/langchain`.

Si marcaste todo: puedes **defender** ambas implementaciones y su trade-off. El Manual 07 **despliega** el sistema (API Gateway → Lambda → Bedrock) con IaC, logging y CI/eval-gates.

---

## 11. Troubleshooting

| Síntoma | Causa | Solución |
|---|---|---|
| `ImportError` de `AmazonKnowledgeBasesRetriever` | Está en `langchain_aws` (antes en community) | `from langchain_aws import AmazonKnowledgeBasesRetriever` |
| Deprecation warnings | Usas `LLMChain`/`RetrievalQA`/`ChatBedrock` | Migra a **LCEL** + **`ChatBedrockConverse`** |
| El retriever no filtra | `retrieval_config` mal formado | Usa la misma estructura `vectorSearchConfiguration` del Manual 03 |
| LangSmith no traza | Falta `LANGSMITH_TRACING=true` o API key | Exporta las variables antes de correr |
| `AccessDenied` | Modelo/KB sin permiso | Habilita Claude; permisos `bedrock:*` del Manual 04 |

---

## 12. Glosario

- **LangChain:** librería de orquestación de apps LLM.
- **LCEL:** encadenar Runnables con el operador `|`.
- **Runnable:** unidad invocable (con streaming/async).
- **ChatBedrockConverse:** chat model de LangChain sobre la Converse API.
- **BedrockEmbeddings:** embeddings de Bedrock en LangChain.
- **AmazonKnowledgeBasesRetriever:** retriever sobre una KB de Bedrock.
- **create_retrieval_chain / create_stuff_documents_chain:** helpers de cadena RAG.
- **LangSmith:** observabilidad/tracing de LangChain.
- **Langfuse:** alternativa open-source de tracing.

---

## 13. Fuentes

Verificadas el **21 de julio de 2026**:

- Integraciones AWS en LangChain — [docs.langchain.com/oss/python/integrations/providers/aws](https://docs.langchain.com/oss/python/integrations/providers/aws)
- `ChatBedrockConverse` (referencia) — [reference.langchain.com/python/langchain-aws/chat_models/bedrock_converse/ChatBedrockConverse](https://reference.langchain.com/python/langchain-aws/chat_models/bedrock_converse/ChatBedrockConverse)
- `AmazonKnowledgeBasesRetriever` — [python.langchain.com/api_reference/aws/retrievers/langchain_aws.retrievers.bedrock.AmazonKnowledgeBasesRetriever.html](https://python.langchain.com/api_reference/aws/retrievers/langchain_aws.retrievers.bedrock.AmazonKnowledgeBasesRetriever.html)
- LCEL (conceptos) — [python.langchain.com/docs/concepts/lcel/](https://python.langchain.com/docs/concepts/lcel/)
- LangSmith — [docs.smith.langchain.com](https://docs.smith.langchain.com/)

---

> **➡️ Siguiente manual:** `07_despliegue_produccion.md` — exponer el copilot como **API en producción**: **API Gateway → Lambda → Bedrock/KB**, **IaC con CDK o Terraform**, **IAM de mínimo privilegio**, **CloudWatch** (logs/métricas/costo), manejo de errores/timeouts/retries, **streaming**, y **CI/CD con eval-gates** (GitHub Actions que corre las evals del Manual 05 y bloquea el merge si baja la calidad).
