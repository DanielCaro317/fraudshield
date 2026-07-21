# Manual 03 — Retrieve, RetrieveAndGenerate y control del prompt (boto3)

> **Objetivo:** Abrir la "caja negra" del RAG gestionado. Aprenderás las **dos APIs** de una Knowledge Base — **`Retrieve`** (solo recupera fragmentos) y **`RetrieveAndGenerate`** (recupera + redacta + cita) — cuándo usar cada una, cómo **filtrar por metadata** (`pais = CO`), cómo activar **búsqueda híbrida**, y cómo tomar el patrón **`Retrieve` + `Converse`** para **controlar tú el prompt, la lógica de rechazo y las citas**. Este es el manual donde dejas de "usar un chatbot que funciona" y empiezas a **diseñar un sistema RAG que gobiernas**.
>
> **Por qué importa para tu empleo:** las vacantes AWS/RAG piden a alguien que sepa **cuándo delegar y cuándo controlar**. Saber decir *"uso `RetrieveAndGenerate` para prototipar y `Retrieve` + `Converse` cuando necesito controlar prompt, guardrails y ranking"* te posiciona como senior.
>
> **Tiempo estimado:** 2–3 horas.
> **Requisitos:** [Manual 02](./02_bedrock_kb_opensearch.md) (KB creada y sincronizada, con metadata).

> ⚠️ **Costo:** si en el Manual 02 usaste **OpenSearch Serverless**, necesitas la KB **encendida** para este manual. Vuelve a crearla (o úsala si la dejaste con **S3 Vectors**) y **bórrala al terminar** (Manual 02 §11). La **búsqueda híbrida (§7) requiere OpenSearch** — si usaste S3 Vectors, esa parte la lees pero no la corres.

---

## 🖱️ / ⌨️ Cómo leer este manual

Este manual es **casi todo código** (boto3), porque el control fino vive en el código, no en la consola. Trabaja en tu notebook/`retrieval/` y **mira cada salida**: los `score`, la metadata, las citas. Ahí está el aprendizaje.

---

## 📋 Tabla de contenido

1. [Las dos APIs: Retrieve vs RetrieveAndGenerate](#1-dos-apis)
2. [Setup del cliente](#2-setup)
3. [Paso A — Retrieve puro (ver chunks, scores, metadata)](#3-retrieve)
4. [Paso B — Filtros por metadata](#4-filtros)
5. [Paso C — Búsqueda híbrida (semántica + keyword)](#5-hibrida)
6. [Paso D — Retrieve + Converse: tú controlas el prompt](#6-retrieve-converse)
7. [Paso E — RetrieveAndGenerate avanzado (prompt template + sesiones)](#7-rag-avanzado)
8. [Cuándo usar cada patrón (decisión)](#8-decision)
9. [Punto de integración con Guardrails (adelanto)](#9-guardrails)
10. [✅ Checklist final](#10-checklist)
11. [🛟 Solución de problemas](#11-troubleshooting)
12. [📖 Glosario](#12-glosario)
13. [🔗 Fuentes (verificadas jul-2026)](#13-fuentes)

---

## 1. Dos APIs

Una Knowledge Base te da **dos** formas de consumirla. Entender la diferencia es el corazón de este manual.

| | **`Retrieve`** | **`RetrieveAndGenerate`** |
|---|---|---|
| Qué hace | Solo **recupera** los chunks relevantes (con score y metadata) | Recupera **y** redacta la respuesta **y** la cita |
| Quién arma el prompt | **Tú** | AWS (con plantilla, personalizable) |
| Control del ranking / filtros | **Total** | Sí (mismo config de retrieval) |
| Lógica de rechazo, tono, formato | **Tú lo defines** | Limitado a la plantilla |
| Aplicar Guardrails, post-proceso, tools | **Fácil** (tú tienes los chunks) | Vía config |
| Ideal para | Producción con requisitos finos | Prototipar rápido / respuestas estándar |

💡 **La regla mental:** `RetrieveAndGenerate` = "modo automático". `Retrieve` + tu propia generación con **`Converse`** = "modo manual con volante". Un profesional usa ambos según el caso.

---

## 2. Setup

```python
import boto3

REGION = "us-east-1"
KB_ID = "<TU_KB_ID>"                       # del Manual 02
MODEL_ID = "<MODEL_ID_CLAUDE>"             # del Playground (Manual 00)
MODEL_ARN = f"arn:aws:bedrock:{REGION}::foundation-model/{MODEL_ID}"

agent = boto3.client("bedrock-agent-runtime", region_name=REGION)   # consultar la KB
bedrock = boto3.client("bedrock-runtime", region_name=REGION)       # Converse (generación propia)
```

---

## 3. Retrieve

📖 **`Retrieve`:** le das una pregunta y te devuelve los **k fragmentos más relevantes**, cada uno con su **score**, su **ubicación (fuente)** y su **metadata**. No redacta nada. Es el equivalente exacto a tu función `retrieve()` del Manual 01, pero contra el índice gestionado.

```python
def retrieve(question: str, k: int = 5, filtro: dict | None = None,
             search_type: str = "SEMANTIC") -> list[dict]:
    vsc = {"numberOfResults": k, "overrideSearchType": search_type}
    if filtro:
        vsc["filter"] = filtro
    resp = agent.retrieve(
        knowledgeBaseId=KB_ID,
        retrievalQuery={"text": question},
        retrievalConfiguration={"vectorSearchConfiguration": vsc},
    )
    return resp["retrievalResults"]

for r in retrieve("¿Qué hago si un cliente reporta una transacción no reconocida?", k=3):
    fuente = r["location"].get("s3Location", {}).get("uri", "?")
    print(f"score={r['score']:.3f}  fuente={fuente}")
    print(f"  metadata={r.get('metadata', {})}")
    print(f"  texto={r['content']['text'][:110]}...\n")
```

### ✅ Checkpoint 3
Ves 3 resultados con `score`, `fuente` (URI de S3) y `metadata` (los campos `pais`, `tipo`, etc. del Manual 02). **Ahora tienes los chunks en tus manos** — puedes hacer lo que quieras con ellos.

💡 **Recuerda la lección del Manual 01:** mira los scores. Si el #3 tiene score bajo, probablemente es ruido. Aquí puedes **filtrar por umbral** tú mismo (`if r["score"] > 0.4`), algo que el modo automático no te deja hacer tan fácil.

---

## 4. Filtros

📖 **Filtro por metadata:** restringir la búsqueda a chunks cuyos atributos cumplan una condición. Ej.: solo documentos de Colombia, solo procedimientos, solo vigentes. Se pasa en el campo `filter`.

**Operadores disponibles:** `equals`, `notEquals`, `in`, `notIn`, `startsWith`, `stringContains`, `listContains`, `greaterThan`, `greaterThanOrEquals`, `lessThan`, `lessThanOrEquals`, y los lógicos **`andAll`** / **`orAll`** (combinan hasta 5 condiciones).

**a) Filtro simple (`equals`):**
```python
solo_co = {"equals": {"key": "pais", "value": "CO"}}
res = retrieve("plazo de un reclamo", k=5, filtro=solo_co)
print("resultados en CO:", len(res))
```

**b) Filtro compuesto (`andAll`):** procedimientos **y** de Colombia:
```python
filtro = {
    "andAll": [
        {"equals": {"key": "pais", "value": "CO"}},
        {"equals": {"key": "tipo", "value": "procedimiento"}},
    ]
}
res = retrieve("congelar la cuenta", k=5, filtro=filtro)
```

**c) Alternativas (`in`):** varios tipos a la vez:
```python
filtro = {"in": {"key": "tipo", "value": ["procedimiento", "politica"]}}
```

### ✅ Checkpoint 4
Con el filtro `pais = CO` (o `andAll`) recuperas **solo** los chunks que cumplen. Cambia el valor a `"US"` y verifica que devuelve **0** — así confirmas que el filtro **de verdad** restringe.

💡 **Filtros numéricos / de fecha:** operadores como `greaterThan` funcionan sobre **números**. Para filtrar por fecha ("vigente después de 2025"), guarda en la metadata un campo **numérico** (ej. `"anio": 2025`) y usa `{"greaterThanOrEquals": {"key": "anio", "value": 2025}}`. Las fechas como texto no se comparan como números.

💬 **Frase de entrevista:** *"El filtrado por metadata es clave para control de acceso y relevancia: sirvo solo documentos vigentes, del país del usuario o del producto consultado — y es la base de un RAG multi-tenant seguro."* (Lo profundizamos en el Manual 08.)

---

## 5. Hibrida

📖 **Búsqueda híbrida:** combina la **semántica** (embeddings, por significado) con la de **texto crudo / keyword** (coincidencia exacta de términos). Recupera lo mejor de ambas — justo el contraste que viste en el Manual 01 (§11) con `APP-2025`.

```python
# ⚠️ Solo funciona si el vector store es OpenSearch Serverless.
print("SEMÁNTICA:")
for r in retrieve("código de tipología APP-2025", k=3, search_type="SEMANTIC"):
    print("  ", r["score"], r["content"]["text"][:70])

print("HÍBRIDA:")
for r in retrieve("código de tipología APP-2025", k=3, search_type="HYBRID"):
    print("  ", r["score"], r["content"]["text"][:70])
```

### ✅ Checkpoint 5
Comparas ambos modos. Para un **término exacto** como un código, la híbrida suele traer el chunk correcto más arriba. **Ya puedes explicar por qué la híbrida mejora el retrieval** — y que requiere OpenSearch.

🔁 **GCP:** Vertex AI Search también ofrece búsqueda híbrida; el concepto es idéntico.

🛟 *`ValidationException` con HYBRID:* tu vector store no lo soporta (S3 Vectors). Usa `SEMANTIC`, o monta OpenSearch para esta demo.

---

## 6. Retrieve Converse

Aquí está **el patrón que te da el control total**: recuperas con `Retrieve`, y **rediactas tú** con `Converse` (como en el Manual 01, pero sobre el índice gestionado). Controlas el prompt, el tono, el formato, el **rechazo** y las **citas**.

```python
def build_prompt(question: str, chunks: list[dict]) -> str:
    contexto = "\n\n".join(
        f"[Fuente: {c['location'].get('s3Location', {}).get('uri', '?')}]\n{c['content']['text']}"
        for c in chunks
    )
    return (
        "Eres un asistente de políticas de un banco. Responde USANDO ÚNICAMENTE el "
        "contexto. Cita la fuente entre corchetes tras cada afirmación. Si el contexto "
        "no contiene la respuesta, di exactamente: 'No encuentro esa información en las "
        "políticas disponibles.'\n\n"
        f"### Contexto\n{contexto}\n\n### Pregunta\n{question}\n\n### Respuesta:"
    )

def answer(question: str, k: int = 4, filtro: dict | None = None,
           umbral: float = 0.4) -> str:
    chunks = retrieve(question, k=k, filtro=filtro)
    # Control propio: descartar por umbral de score
    chunks = [c for c in chunks if c["score"] >= umbral]
    if not chunks:
        return "No encuentro esa información en las políticas disponibles."
    prompt = build_prompt(question, chunks)
    resp = bedrock.converse(
        modelId=MODEL_ID,
        messages=[{"role": "user", "content": [{"text": prompt}]}],
        inferenceConfig={"temperature": 0.0, "maxTokens": 500},
    )
    return resp["output"]["message"]["content"][0]["text"]

print(answer("¿Qué debo verificar en una transferencia internacional grande?",
             filtro={"equals": {"key": "pais", "value": "CO"}}))
```

### ✅ Checkpoint 6
La respuesta se basa en tus chunks filtrados y cita fuentes. Prueba una pregunta sin respuesta → devuelve el **rechazo controlado**. **Este patrón es el que usarás en la API del Manual 07** (y donde enchufarás Guardrails).

💡 **Lo que ganaste vs `RetrieveAndGenerate`:** umbral de score propio, rechazo con tu redacción exacta, control del prompt, y un punto natural para meter **Guardrails** (Manual 04), **re-ranking** o **tools** de un agente.

---

## 7. RAG avanzado

Si prefieres el modo gestionado pero **con tu toque**, `RetrieveAndGenerate` acepta **plantilla de prompt** y **filtros**, y mantiene **sesión conversacional**.

**a) Con plantilla de prompt y filtro:**
```python
def rag_generate(question: str, filtro: dict | None = None, session_id: str | None = None):
    vsc = {"numberOfResults": 5}
    if filtro:
        vsc["filter"] = filtro
    cfg = {
        "type": "KNOWLEDGE_BASE",
        "knowledgeBaseConfiguration": {
            "knowledgeBaseId": KB_ID,
            "modelArn": MODEL_ARN,
            "retrievalConfiguration": {"vectorSearchConfiguration": vsc},
            "generationConfiguration": {
                # $search_results$ = donde se inyectan los chunks recuperados
                "promptTemplate": {"textPromptTemplate":
                    "Eres un asistente de políticas bancarias. Usa solo estos resultados:\n"
                    "$search_results$\n"
                    "Si no está la respuesta, dilo. Cita la fuente. Pregunta: "},
                "inferenceConfig": {"textInferenceConfig": {"temperature": 0.0, "maxTokens": 500}},
            },
        },
    }
    kwargs = {"input": {"text": question}, "retrieveAndGenerateConfiguration": cfg}
    if session_id:
        kwargs["sessionId"] = session_id
    return agent.retrieve_and_generate(**kwargs)

r = rag_generate("¿Cuándo se retiene una transferencia?",
                 filtro={"equals": {"key": "pais", "value": "CO"}})
print(r["output"]["text"])
print("sessionId:", r["sessionId"])   # guárdalo para la siguiente pregunta del mismo hilo
```

**b) Conversación multi-turno:** reusa el `sessionId` devuelto para que recuerde el contexto:
```python
r2 = rag_generate("¿Y quién debe aprobarla?", session_id=r["sessionId"])
print(r2["output"]["text"])
```

### ✅ Checkpoint 7
La plantilla cambia el estilo de la respuesta, el filtro la restringe, y con `sessionId` la segunda pregunta ("¿y quién la aprueba?") **entiende el contexto** de la primera. Tienes el modo gestionado **afinado**.

💡 **`$search_results$`** es el marcador donde Bedrock inserta los chunks. Hay otros (como instrucciones de formato). Personalizar la plantilla es la forma "gestionada" de controlar el tono sin renunciar a la comodidad.

---

## 8. Decision

Tu árbol de decisión (memorízalo para la entrevista):

```
¿Necesito control fino del prompt, umbral, rechazo, guardrails o tools?
├── SÍ  → Retrieve + Converse   (modo manual con volante)   → API del proyecto
└── NO  → RetrieveAndGenerate   (modo automático)
          ├── ¿Necesito ajustar tono/filtros/sesión? → con promptTemplate + filter + sessionId
          └── ¿Solo una respuesta rápida?            → configuración mínima
```

| Patrón | Úsalo cuando |
|---|---|
| `RetrieveAndGenerate` mínimo | Prototipo, demo, respuestas estándar |
| `RetrieveAndGenerate` + plantilla/filtro/sesión | Chat gestionado con tono y contexto propios |
| `Retrieve` + `Converse` | **Producción con requisitos finos**: umbral, rechazo, Guardrails, re-ranking, agentes |

---

## 9. Guardrails

Fíjate en la función `answer()` del §6: hay **dos puntos naturales** para meter seguridad, que es exactamente lo que construiremos en el **Manual 04**:

1. **Antes de recuperar** — inspeccionar la **entrada** del usuario (¿prompt injection? ¿PII? ¿tema prohibido?).
2. **Antes de devolver** — inspeccionar la **salida** del modelo (¿fugó datos sensibles? ¿respondió algo fuera de política? ¿está de verdad anclada al contexto — *contextual grounding*?).

Con **Bedrock Guardrails** esto se hace de forma declarativa y se aplica tanto en `Converse` (con `guardrailConfig`) como en `RetrieveAndGenerate`. Ese es el siguiente manual — **tu mayor diferenciador**.

💬 **Frase de entrevista:** *"Aplico defensa en profundidad: Guardrails sobre input y output, umbral de similitud en el retrieval, y el modelo instruido a responder solo con el contexto y a citar. Si la evidencia es insuficiente, rechazo."*

---

## 10. Checklist

- [ ] Sé la diferencia entre **`Retrieve`** y **`RetrieveAndGenerate`** y cuándo usar cada una.
- [ ] Recupero chunks con **score, fuente y metadata** y sé aplicar **umbral**.
- [ ] Filtro por metadata (**`equals`**, **`andAll`**, **`in`**) y verifiqué que restringe.
- [ ] Entiendo la **búsqueda híbrida** y que requiere OpenSearch.
- [ ] Implementé **`Retrieve` + `Converse`** con prompt, rechazo y citas **propios**.
- [ ] Usé **`RetrieveAndGenerate`** con **plantilla**, **filtro** y **sesión** conversacional.
- [ ] Tengo claro el **árbol de decisión** entre patrones.
- [ ] Identifico **dónde** enchufaré Guardrails (input/output).
- [ ] (Si usé OpenSearch) **borré** el recurso al terminar.

Si marcaste todo: **gobiernas** el RAG de Bedrock, no solo lo usas. El Manual 04 le pone **seguridad de producción** con Guardrails.

---

## 11. Troubleshooting

| Síntoma | Causa | Solución |
|---|---|---|
| `retrieve` devuelve `[]` | Filtro demasiado estricto o KB sin sync | Afloja el filtro; re-sincroniza (Manual 02 §7) |
| Filtro no restringe | La metadata no se ingirió | Verifica los `.metadata.json` en S3 y re-sync |
| `ValidationException` con `HYBRID` | Store no compatible (S3 Vectors) | Usa `SEMANTIC` o monta OpenSearch |
| `AccessDeniedException` | Falta permiso o modelo no habilitado | Habilita Claude; permiso `bedrock:Retrieve`, `bedrock:RetrieveAndGenerate` |
| La sesión "olvida" | No reusaste el `sessionId` | Pasa el `sessionId` devuelto en la llamada siguiente |
| `modelArn` inválido | ARN mal formado o requiere inference profile | Usa el ARN base o el del inference profile del Playground |

---

## 12. Glosario

- **Retrieve:** API que solo recupera chunks (con score/metadata/fuente).
- **RetrieveAndGenerate:** API que recupera + redacta + cita.
- **overrideSearchType:** `SEMANTIC` (vectores) o `HYBRID` (vectores + texto).
- **filter / RetrievalFilter:** condición sobre metadata (`equals`, `andAll`, `in`…).
- **numberOfResults:** el top-k del retrieval.
- **promptTemplate / `$search_results$`:** plantilla de generación en `RetrieveAndGenerate`.
- **sessionId:** identificador para conversación multi-turno.
- **Umbral de score:** descartar chunks poco relevantes (control propio).
- **Grounding:** que la respuesta se ancle a los chunks recuperados.

---

## 13. Fuentes

Verificadas el **21 de julio de 2026**:

- `Retrieve` (API) — [docs.aws.amazon.com/bedrock/latest/APIReference/API_agent-runtime_Retrieve.html](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_agent-runtime_Retrieve.html)
- `RetrievalFilter` (operadores de metadata) — [docs.aws.amazon.com/bedrock/latest/APIReference/API_agent-runtime_RetrievalFilter.html](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_agent-runtime_RetrievalFilter.html)
- Configurar y personalizar consultas y generación (plantilla, híbrida) — [docs.aws.amazon.com/bedrock/latest/userguide/kb-test-config.html](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-test-config.html)
- `retrieve` / `retrieve_and_generate` (boto3) — [boto3 bedrock-agent-runtime](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/bedrock-agent-runtime.html)

---

> **➡️ Siguiente manual:** `04_guardrails_seguridad.md` — **Bedrock Guardrails como módulo completo** (tu mayor diferenciador): content filters, prompt-attack detection, denied topics, filtros de PII/información sensible, **contextual grounding**, y defensa en profundidad (IAM de mínimo privilegio, logging, aislamiento del contexto). Responderás con evidencia la pregunta *"¿has usado Guardrails?"*.
