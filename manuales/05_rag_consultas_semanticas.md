# Manual 05 — RAG: consultas semánticas y cualitativas

> **Objetivo:** Construir un asistente **RAG** (Retrieval-Augmented Generation) que permita a un analista antifraude hacer **preguntas en lenguaje natural** sobre las narrativas de quejas de clientes ("¿qué patrones de estafa por transferencia reportan?", "resume las quejas de cargos no autorizados"). Aprenderás la arquitectura RAG completa **y los temas senior que Proxify exige y que fueron tu gap**: embeddings, vector DB, **hybrid search**, **re-ranking**, **prompt engineering**, **evaluación con RAGAS** y **observabilidad (tracing)**.
>
> **Tiempo estimado:** 8–10 horas (es el manual más importante; tómalo con calma).
> **Prerrequisito:** Manual 01 (tabla `fraud_raw.complaints`) + Manual 00 Parte B (entorno local con **Ollama**).
> **Cubre del cargo:** LLMs, **arquitectura RAG**, consultas semánticas (Ceiba) · **RAG, embeddings, IR avanzado, prompt eng., evaluación** (Proxify — núcleo del rol y de tu entrevista).
> **Dónde:** **tu PC local** (RTX 4070 Super + Ollama = LLM y embeddings **gratis**). 🔁 callouts de AWS/GCP gestionado.

---

## 🖱️ / ⌨️ Cómo leer este manual (RAG es código, pero lo hacemos amable)

Seré honesto contigo, porque es importante: **un RAG se construye con código.** No existe un botón "arma mi RAG" — y precisamente *por eso* Proxify lo evalúa: es la habilidad central del rol. La buena noticia: lo hacemos lo más visual y guiado posible.

- 🖱️ **Corre el código en un notebook (recomendado para semi-junior).** En vez de lanzar scripts a ciegas en la terminal, abre un **notebook Jupyter en VS Code** (extensión Jupyter) y pega cada bloque en una celda. Ejecutas con **Shift+Enter** y **ves el resultado de cada paso** (los chunks, las quejas recuperadas, la respuesta del LLM). Es la forma más intuitiva de *entender* lo que pasa.
- 🖱️ **Hay partes con UI real:** exportar las quejas (consola de BigQuery / Cloud Storage), y el **dashboard de Langfuse** (observabilidad, §12) que es 100% visual.
- ⌨️ **Terminal:** también puedes guardar cada bloque como un `.py` y correrlo con `python archivo.py`. Te doy los nombres de archivo por si prefieres esa vía.

> 💡 **¿Existe un RAG "sin código"?** Sí: **Vertex AI Search** (antes "Agent Builder / Enterprise Search") arma un RAG gestionado subiendo documentos por consola, casi sin programar. Es una alternativa válida para un producto rápido — pero **no te enseña las piezas** (chunking, embeddings, hybrid, re-ranking, evaluación) que te van a preguntar en la entrevista. Por eso aquí lo construimos a mano. Menciona Vertex AI Search como "la opción gestionada" y sabrás de qué hablas.

👉 **Plan sugerido:** haz todo el manual en un notebook, celda por celda. Cuando funcione, guarda los scripts `.py` para el repo (los usarás en la API del Manual 06).

---

## 📋 Tabla de contenido

1. [Conceptos previos](#1-conceptos-previos)
2. [La arquitectura RAG (dibújala de memoria)](#2-arquitectura)
3. [Entorno local (Ollama + Python)](#3-entorno)
4. [Traer los datos: exportar quejas de BigQuery a tu PC](#4-datos)
5. [Paso 1 — Cargar y "chunkear" documentos](#5-chunking)
6. [Paso 2 — Embeddings e indexación en ChromaDB](#6-embeddings)
7. [Paso 3 — Retrieval básico (búsqueda semántica)](#7-retrieval)
8. [Paso 4 — Generación: el RAG completo con citas](#8-generacion)
9. [Paso 5 — Retrieval avanzado: hybrid search + re-ranking](#9-avanzado)
10. [Paso 6 — Prompt engineering (anti-alucinación)](#10-prompt)
11. [Paso 7 — Evaluación con RAGAS](#11-ragas)
12. [Paso 8 — Observabilidad: tracing con Langfuse](#12-tracing)
13. [Vector DB en producción (pgvector / Vertex / AWS)](#13-produccion)
14. [Commit a GitHub](#14-commit)
15. [✅ Checklist final](#15-checklist)
16. [🛟 Solución de problemas](#16-troubleshooting)
17. [📖 Glosario](#17-glosario)

---

## 1. Conceptos previos

📖 **LLM (Large Language Model):** modelo que genera texto (Claude, GPT, Llama). Sabe mucho del mundo, pero **NO conoce los datos privados de tu banco** y puede **alucinar** (inventar).

📖 **RAG (Retrieval-Augmented Generation):** técnica para que el LLM responda usando **tus documentos**. En vez de "preguntarle de memoria", primero **recuperas** los fragmentos relevantes de tus datos y se los das al LLM como contexto para que responda **fundamentado** (grounded) y **con citas**. Reduce alucinaciones y permite datos privados/frescos sin reentrenar.

📖 **Embedding:** una representación numérica (vector) del significado de un texto. Textos con significado parecido tienen vectores cercanos. Es lo que permite la **búsqueda semántica** (por significado, no por palabras exactas).

📖 **Vector database:** base de datos especializada en guardar embeddings y encontrar los más parecidos a una consulta (vecinos más cercanos). Ej.: **ChromaDB** (local), **pgvector**, **Pinecone**, **Qdrant**.

📖 **Chunking:** partir documentos largos en fragmentos ("chunks") para indexarlos. Si el chunk es muy grande, el retrieval pierde precisión; si es muy chico, pierde contexto.

📖 **Búsqueda semántica vs por palabra clave:**
- **Semántica (densa/embeddings):** entiende significado ("estafa" ≈ "fraude" ≈ "engaño").
- **Por palabra clave (BM25):** encuentra términos exactos (un ID, un nombre).
- **Hybrid search:** combina ambas → lo mejor de los dos mundos (tema senior, §9).

💡 **El caso:** indexamos las narrativas de quejas; el analista pregunta en lenguaje natural; el RAG recupera quejas relevantes y el LLM responde citándolas.

---

## 2. Arquitectura

Memoriza este diagrama — **te lo van a pedir dibujar en la entrevista de Proxify**:

```
  INGESTA (una vez)                         CONSULTA (cada pregunta)
  ┌─────────────────────┐                   ┌──────────────────────────┐
  │ Documentos (quejas) │                   │  Pregunta del analista   │
  │        │            │                   │           │              │
  │   1. Chunking       │                   │   1. Embedding query     │
  │        │            │                   │           │              │
  │   2. Embeddings     │                   │   2. RETRIEVAL           │
  │        │            │                   │   (hybrid: dense+BM25)   │
  │        ▼            │                   │           │              │
  │  Vector DB (Chroma) │◄──────────────────┤   3. Re-ranking          │
  └─────────────────────┘    busca los      │           │              │
                             top-k chunks    │   4. AUGMENT prompt      │
                                             │   (contexto + pregunta)  │
                                             │           │              │
                                             │   5. LLM GENERA          │
                                             │   (grounded + citas)     │
                                             │           ▼              │
                                             │   Respuesta con fuentes  │
                                             └──────────────────────────┘
```

**Las 5 etapas de la consulta:** Embed query → **Retrieve** → **Re-rank** → **Augment** → **Generate**.

---

## 3. Entorno

> Trabajaremos en **tu PC local** (no Cloud Shell): tu RTX 4070 Super corre el LLM y los embeddings **gratis** con Ollama, y es mucho más rápido. Abre una terminal (PowerShell) en tu PC, o el terminal integrado de VS Code.

### 3.1 — Verificar Ollama (lo instalaste en el Manual 00 Parte B)
```powershell
ollama --version
ollama list
```
Debes tener `llama3.1:8b` y `nomic-embed-text`. Si no:
```powershell
ollama pull llama3.1:8b
ollama pull nomic-embed-text
```

### 3.2 — Crear el entorno Python del RAG
En tu repo local `fraudshield`:
```powershell
cd fraudshield\rag
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```
💡 Si PowerShell bloquea el script de activación: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` y reintenta.

### 3.3 — Instalar dependencias
```powershell
pip install langchain langchain-community langchain-ollama langchain-chroma langchain-text-splitters chromadb rank_bm25 sentence-transformers pandas
pip install jupyter ipykernel   # para trabajar en notebook dentro de VS Code
```
💡 (RAGAS y Langfuse los instalamos en sus pasos para no demorar esto.)

🖱️ **Para el modo notebook:** en VS Code, instala la extensión **Jupyter**, crea un archivo `rag/explorar.ipynb`, y arriba a la derecha elige el kernel de tu `.venv`. Cada bloque de código de este manual va en una celda.

### ✅ Checkpoint 3
`ollama list` muestra los 2 modelos; el entorno virtual está activo (verás `(.venv)` en el prompt); las librerías instalaron sin error.

---

## 4. Datos

Las quejas están en BigQuery (`fraud_raw.complaints`). Las exportamos a un CSV y lo bajamos a tu PC.

🖱️ **Por la UI (consola):**
1. **BigQuery** → editor → RUN:
   ```sql
   CREATE OR REPLACE TABLE `fraud_dbt.complaints_sample` AS
   SELECT * FROM `fraud_raw.complaints` LIMIT 3000;
   ```
2. Explorer → tabla `complaints_sample` → **⋮ → Export → Export to GCS** → `.../curated/complaints_sample.csv` (CSV).
3. **Cloud Storage** → tu bucket → `curated/` → clic en `complaints_sample.csv` → **DOWNLOAD**. Guárdalo en `fraudshield\rag\`.

⌨️ **Equivalente en CLI (Cloud Shell):**
```bash
export PROJECT_ID=$(gcloud config get-value project)
export BUCKET="gs://${PROJECT_ID}-datalake"
bq query --use_legacy_sql=false --replace \
  --destination_table=fraud_dbt.complaints_sample \
  'SELECT * FROM `fraud_raw.complaints` LIMIT 3000'
bq extract --destination_format=CSV \
  fraud_dbt.complaints_sample "$BUCKET/curated/complaints_sample.csv"
gcloud storage cp "$BUCKET/curated/complaints_sample.csv" ~/
# luego: Cloud Shell menú ⋮ → Download → complaints_sample.csv
```

### ✅ Checkpoint 4
Tienes `fraudshield\rag\complaints_sample.csv` en tu PC.

---

## 5. Chunking

En una celda de notebook, o como `rag\ingest.py`:
```python
"""Carga las quejas, las parte en chunks y prepara los documentos."""
import pandas as pd
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.documents import Document

df = pd.read_csv("complaints_sample.csv")

# Detectar la columna de narrativa (texto) automáticamente
narr_col = next((c for c in df.columns if "narrative" in c.lower()), None)
assert narr_col, f"No encontré columna de narrativa. Columnas: {list(df.columns)}"
df = df[df[narr_col].notna()].reset_index(drop=True)
print(f"{len(df)} quejas con narrativa.")

# Construir documentos con metadatos (para citar la fuente)
docs = []
for i, row in df.iterrows():
    meta = {"id": str(i)}
    for c in ("product", "issue", "company", "date_received", "state"):
        col = next((x for x in df.columns if x.lower().replace(" ", "_") == c), None)
        if col:
            meta[c] = str(row[col])
    docs.append(Document(page_content=str(row[narr_col]), metadata=meta))

# Chunking: 800 caracteres con 100 de solape
splitter = RecursiveCharacterTextSplitter(chunk_size=800, chunk_overlap=100)
chunks = splitter.split_documents(docs)
print(f"{len(docs)} documentos -> {len(chunks)} chunks")

# Guardar para reusar
import pickle
with open("chunks.pkl", "wb") as f:
    pickle.dump(chunks, f)
print("Chunks guardados en chunks.pkl")
```
Ejecuta la celda (o `python ingest.py`).

💡 **Por qué chunk_size=800/overlap=100:** las narrativas de quejas son medianas; 800 caracteres captura un evento completo, y el solape evita cortar ideas a la mitad. **El chunking es una decisión de diseño** que afecta la calidad (tema de entrevista).

### ✅ Checkpoint 5
Imprime el nº de chunks y crea `chunks.pkl`.

---

## 6. Embeddings

Celda de notebook, o `rag\index.py`:
```python
"""Genera embeddings de los chunks y los indexa en ChromaDB."""
import pickle
from langchain_ollama import OllamaEmbeddings
from langchain_chroma import Chroma

with open("chunks.pkl", "rb") as f:
    chunks = pickle.load(f)

# Embeddings locales con tu GPU (gratis)
emb = OllamaEmbeddings(model="nomic-embed-text")

# Indexar en una base vectorial persistente
db = Chroma.from_documents(
    documents=chunks,
    embedding=emb,
    persist_directory="./chroma_db",
    collection_name="complaints",
)
print(f"Indexados {len(chunks)} chunks en ./chroma_db")
```
💡 La primera vez tarda según el nº de chunks (tu GPU lo acelera). Crea la carpeta `chroma_db/` (la base vectorial persistente).

### ✅ Checkpoint 6
Existe la carpeta `rag\chroma_db\` y el código imprime cuántos chunks indexó.

---

## 7. Retrieval

Probemos la **búsqueda semántica** sola (sin LLM todavía). Celda o `rag\test_retrieval.py`:
```python
from langchain_ollama import OllamaEmbeddings
from langchain_chroma import Chroma

emb = OllamaEmbeddings(model="nomic-embed-text")
db = Chroma(persist_directory="./chroma_db", embedding_function=emb, collection_name="complaints")

query = "estafa por transferencia no autorizada"
results = db.similarity_search(query, k=4)

print(f"Top 4 quejas para: '{query}'\n")
for d in results:
    print(f"[{d.metadata.get('id')}] {d.page_content[:200]}...\n")
```
💡 Nota que encuentra quejas **por significado** aunque no contengan las palabras exactas. Eso es búsqueda semántica.

### ✅ Checkpoint 7
El retrieval devuelve quejas relevantes a la consulta.

---

## 8. Generacion

Ahora el RAG completo: recuperar + **generar** una respuesta fundamentada con citas. `rag\rag.py`:
```python
"""RAG completo: retrieval + generación con LLM local, respuesta con citas."""
from langchain_ollama import OllamaEmbeddings, ChatOllama
from langchain_chroma import Chroma
from langchain_core.prompts import ChatPromptTemplate

emb = OllamaEmbeddings(model="nomic-embed-text")
db = Chroma(persist_directory="./chroma_db", embedding_function=emb, collection_name="complaints")
retriever = db.as_retriever(search_kwargs={"k": 4})

llm = ChatOllama(model="llama3.1:8b", temperature=0)

PROMPT = ChatPromptTemplate.from_template(
    """Eres un asistente del departamento de fraude de un banco.
Responde la pregunta del analista USANDO SOLO el contexto de quejas de clientes.
Si el contexto no contiene la respuesta, di: "No tengo suficiente información en las quejas".
Cita las fuentes usando su identificador entre corchetes, ej. [12].

Contexto:
{context}

Pregunta: {question}

Respuesta (en español, con citas):"""
)

def format_docs(docs):
    return "\n\n".join(f"[{d.metadata.get('id')}] {d.page_content}" for d in docs)

def ask(question: str):
    docs = retriever.invoke(question)
    context = format_docs(docs)
    messages = PROMPT.format_messages(context=context, question=question)
    answer = llm.invoke(messages).content
    return answer, docs

if __name__ == "__main__":
    preguntas = [
        "¿Qué patrones de estafa por transferencia reportan los clientes?",
        "Resume las quejas sobre cargos no autorizados en tarjetas.",
        "¿Mencionan robo de identidad? ¿Cómo ocurre?",
    ]
    for q in preguntas:
        ans, docs = ask(q)
        print(f"\n🟦 PREGUNTA: {q}\n")
        print(ans)
        print("\nFuentes:", [d.metadata.get("id") for d in docs])
        print("-" * 70)
```
Ejecuta (`python rag.py` o pega la función `ask` en el notebook y llámala). 🎉 ¡Tu RAG responde preguntas sobre las quejas, **con citas a las fuentes**!

🔁 **Usar Claude en vez de Ollama (calidad producción):** instala `pip install langchain-anthropic`, define tu API key (`$env:ANTHROPIC_API_KEY="..."`) y cambia el LLM:
```python
from langchain_anthropic import ChatAnthropic
llm = ChatAnthropic(model="claude-sonnet-4-6", temperature=0)
```
💡 Para **desarrollar** usa Ollama (gratis); para la **demo/entrevista** puedes mostrar Claude (más potente). El job de Proxify nombra explícitamente Anthropic.

### ✅ Checkpoint 8
El RAG responde las 3 preguntas con citas. Tienes un RAG funcional. 🏆

---

## 9. Avanzado

> 🆕 **Delta Proxify (tu gap):** un RAG básico (solo embeddings) no es nivel senior. Lo elevamos con **hybrid search** y **re-ranking** — exactamente lo que te diferencia.

### 9.1 — Hybrid search (denso + BM25)
Combinamos búsqueda **semántica** (embeddings) con **palabra clave** (BM25). `rag\retrieval_avanzado.py`:
```python
"""Retrieval avanzado: hybrid search (denso + BM25) + re-ranking."""
import pickle
from langchain_ollama import OllamaEmbeddings
from langchain_chroma import Chroma
from langchain_community.retrievers import BM25Retriever
from langchain.retrievers import EnsembleRetriever
from sentence_transformers import CrossEncoder

# 1) Retriever denso (semántico) desde Chroma
emb = OllamaEmbeddings(model="nomic-embed-text")
db = Chroma(persist_directory="./chroma_db", embedding_function=emb, collection_name="complaints")
dense = db.as_retriever(search_kwargs={"k": 8})

# 2) Retriever BM25 (palabra clave) desde los chunks
with open("chunks.pkl", "rb") as f:
    chunks = pickle.load(f)
bm25 = BM25Retriever.from_documents(chunks)
bm25.k = 8

# 3) Ensemble: combina ambos (hybrid search)
hybrid = EnsembleRetriever(retrievers=[dense, bm25], weights=[0.5, 0.5])

# 4) Re-ranking con cross-encoder (re-ordena por relevancia real)
reranker = CrossEncoder("cross-encoder/ms-marco-MiniLM-L-6-v2")

def retrieve_rerank(query: str, top_n: int = 4):
    candidates = hybrid.invoke(query)                 # ~16 candidatos
    pairs = [(query, d.page_content) for d in candidates]
    scores = reranker.predict(pairs)
    ranked = sorted(zip(candidates, scores), key=lambda x: x[1], reverse=True)
    return [d for d, _ in ranked[:top_n]]

if __name__ == "__main__":
    q = "transferencias fraudulentas que vaciaron la cuenta"
    for d in retrieve_rerank(q):
        print(f"[{d.metadata.get('id')}] {d.page_content[:160]}...\n")
```
💡 **Por qué mejora (guion de entrevista):**
- **Hybrid:** el denso entiende significado pero puede perder términos exactos (un nombre, un código); BM25 los captura. Juntos suben el **recall** del retrieval.
- **Re-ranking:** el cross-encoder lee *query + documento juntos* y los re-puntúa con más precisión que la similitud de embeddings → sube la **precisión** del contexto, y por tanto la calidad de la respuesta.

### 9.2 — Conectar el retrieval avanzado al RAG
En `rag.py`, reemplaza el retriever básico por `retrieve_rerank` (impórtalo desde `retrieval_avanzado`). Así tu RAG final usa hybrid + re-ranking.

### ✅ Checkpoint 9
`retrieval_avanzado.py` devuelve resultados re-rankeados. Puedes explicar por qué hybrid + re-ranking mejoran el RAG.

---

## 10. Prompt

> 🆕 **Delta Proxify:** el **prompt engineering** es una disciplina, no improvisación. Estas técnicas reducen alucinaciones (clave en banca).

Técnicas aplicadas (ya viste varias en el prompt de §8):
1. **Rol claro:** "Eres un asistente del departamento de fraude".
2. **Grounding estricto:** "USA SOLO el contexto". → reduce alucinaciones.
3. **Salida controlada ante incertidumbre:** "Si no está en el contexto, di que no hay info". → evita inventar.
4. **Citas obligatorias:** "Cita las fuentes [id]". → trazabilidad.
5. **Idioma e instrucciones de formato** explícitas.

**Mejora opcional — salida estructurada (JSON):** para integrarlo a sistemas, pide JSON:
```python
PROMPT_JSON = ChatPromptTemplate.from_template(
    """... Responde SOLO con JSON válido:
{{"respuesta": "...", "fuentes": ["id1","id2"], "confianza": "alta|media|baja"}}
Contexto: {context}
Pregunta: {question}"""
)
```
💡 **Para entrevista:** "Trato los prompts como **código versionado**, uso **grounding** y **salida estructurada**, y **evalúo** los cambios con RAGAS en vez de juzgarlos a ojo." (Justo lo que sigue.)

### ✅ Checkpoint 10
Entiendes y puedes nombrar 4–5 técnicas de prompt engineering anti-alucinación.

---

## 11. Ragas

> 🆕 **Delta Proxify (tu mayor gap en la entrevista).** "¿Cómo testeas un RAG?" → con **RAGAS**: mide la calidad **objetivamente**.

📖 **Métricas de RAGAS:**
- **faithfulness:** ¿la respuesta está fundamentada en el contexto? (baja = alucinación)
- **answer_relevancy:** ¿la respuesta responde la pregunta?
- **context_precision:** ¿el contexto recuperado era relevante?
- **context_recall:** ¿se recuperó toda la info necesaria? (requiere "ground truth")

### 11.1 — Instalar
```powershell
pip install ragas datasets
```

### 11.2 — Crear el set de evaluación y correr RAGAS
`rag\evaluate_rag.py`:
```python
"""Evalúa el RAG con RAGAS (faithfulness, relevancy, context precision/recall)."""
from datasets import Dataset
from ragas import evaluate
from ragas.metrics import faithfulness, answer_relevancy, context_precision, context_recall
from ragas.llms import LangchainLLMWrapper
from ragas.embeddings import LangchainEmbeddingsWrapper
from langchain_ollama import ChatOllama, OllamaEmbeddings
from rag import ask   # reutiliza tu RAG

# Golden set: preguntas + respuesta esperada (ground truth)
golden = [
    {"q": "¿Reportan cargos no autorizados en tarjetas?",
     "gt": "Sí, varios clientes reportan cargos que no reconocen en sus tarjetas."},
    {"q": "¿Qué dicen sobre robo de identidad?",
     "gt": "Algunos clientes describen apertura de cuentas o cargos a su nombre sin consentimiento."},
]

data = {"question": [], "answer": [], "contexts": [], "ground_truth": []}
for item in golden:
    ans, docs = ask(item["q"])
    data["question"].append(item["q"])
    data["answer"].append(ans)
    data["contexts"].append([d.page_content for d in docs])
    data["ground_truth"].append(item["gt"])

ds = Dataset.from_dict(data)

# Juez = el mismo LLM/embeddings local (gratis)
judge_llm = LangchainLLMWrapper(ChatOllama(model="llama3.1:8b", temperature=0))
judge_emb = LangchainEmbeddingsWrapper(OllamaEmbeddings(model="nomic-embed-text"))

result = evaluate(
    ds,
    metrics=[faithfulness, answer_relevancy, context_precision, context_recall],
    llm=judge_llm,
    embeddings=judge_emb,
)
print(result)
```
Verás un puntaje por métrica (0–1).

💡 **Iteración guiada por datos:** cambia algo (chunk_size, k, hybrid vs solo denso, el prompt) y vuelve a correr RAGAS. Si `faithfulness` o `context_precision` suben, la mejora es real — **no a ojo**. Eso es *eval-driven development* (y en el Manual 06 lo pondremos en CI como **eval-gate**).

🛟 **RAGAS evoluciona rápido**; si una importación cambia, revisa la documentación de tu versión (`pip show ragas`). El concepto (las 4 métricas) es lo que importa para la entrevista.

### ✅ Checkpoint 11
`evaluate_rag.py` imprime las métricas de RAGAS. Puedes explicar faithfulness y context precision.

---

## 12. Tracing

> 🆕 **Delta Proxify:** en producción necesitas **ver** qué hace tu RAG (prompts, contexto, latencia, costo) para depurar. Eso es **observabilidad de LLM**. Esta es una parte **muy visual** (dashboard web).

📖 **Langfuse / LangSmith:** plataformas para **trazar** cada llamada (qué se recuperó, qué prompt se envió, qué respondió, cuántos tokens, cuánto tardó).

### 12.1 — Opción rápida (Langfuse cloud, free tier) 🖱️
1. Crea cuenta en **https://cloud.langfuse.com** → proyecto → copia `PUBLIC_KEY` y `SECRET_KEY`.
2. Instala y configura:
```powershell
pip install langfuse
$env:LANGFUSE_PUBLIC_KEY="pk-..."
$env:LANGFUSE_SECRET_KEY="sk-..."
$env:LANGFUSE_HOST="https://cloud.langfuse.com"
```
3. Añade el callback a tus llamadas LLM:
```python
from langfuse.langchain import CallbackHandler
handler = CallbackHandler()
answer = llm.invoke(messages, config={"callbacks": [handler]}).content
```
4. 🖱️ Abre el **dashboard de Langfuse** en el navegador → verás cada consulta trazada (prompt, contexto, latencia, tokens) en una interfaz visual. Toma una captura para el portafolio. 📸

💡 Es **opcional** para que tu RAG funcione, pero **muy valorado** en Proxify: "instrumento mis cadenas con Langfuse para depurar y monitorear costo/latencia en producción".

🛟 La API de integración de Langfuse cambia entre versiones; si el import falla, revisa su doc para tu versión. Es opcional, no bloquea el resto.

### ✅ Checkpoint 12 (opcional)
Ves al menos una traza de tu RAG en el dashboard de Langfuse.

---

## 13. Produccion

Para el portafolio/entrevista, ten claro cómo escala esto **fuera de tu PC**:

| Componente | Local (dev) | Producción (GCP) | 🔁 AWS |
|---|---|---|---|
| Embeddings/LLM | Ollama | **Vertex AI** / Claude API | **Bedrock** |
| Vector DB | ChromaDB | **pgvector** (Cloud SQL) o **Vertex AI Vector Search** | **OpenSearch** / Bedrock Knowledge Bases |
| RAG gestionado (no-code) | — | **Vertex AI Search** | **Bedrock Knowledge Bases** |
| Tracing | Langfuse cloud | Langfuse self-host / Cloud Logging | Langfuse / CloudWatch |

💡 **Migrar ChromaDB → pgvector** es directo: cambias el `vectorstore` de LangChain (`langchain_postgres.PGVector`) apuntando a una base Postgres con la extensión `pgvector`. La lógica del RAG no cambia. (Lo conectaremos al desplegar, Manuales 06–07.)

🔁 **En AWS:** un RAG gestionado se arma con **Bedrock Knowledge Bases** (retrieval) + un modelo de Bedrock (generación). Mismo concepto, distinto proveedor — sabrás explicarlo.

### ✅ Checkpoint 13
Puedes explicar cómo llevarías este RAG a producción en GCP y su equivalente en AWS.

---

## 14. Commit

⚠️ No subas la base vectorial ni los datos (pesados). Sube el **código**.

🖱️ **Por la UI (VS Code):** Source Control → commit → push (con el `.gitignore` de abajo).

⌨️ **Por CLI:** añade al `.gitignore`:
```
# RAG
rag/.venv/
rag/chroma_db/
rag/*.pkl
rag/*.csv
rag/*.ipynb_checkpoints
```
Luego:
```powershell
git add rag/ingest.py rag/index.py rag/test_retrieval.py rag/rag.py rag/retrieval_avanzado.py rag/evaluate_rag.py .gitignore
git commit -m "Manual 05: RAG de consultas semanticas sobre quejas (embeddings, ChromaDB, hybrid search, re-ranking, RAGAS, tracing)"
git push origin main
```

### ✅ Checkpoint 14
En GitHub aparecen los scripts del RAG (sin datos ni base vectorial).

---

## 15. Checklist

- [ ] Entorno local con Ollama (LLM + embeddings) y venv/notebook funcionando.
- [ ] Quejas exportadas de BigQuery a tu PC.
- [ ] Chunking e indexación en ChromaDB.
- [ ] Retrieval semántico probado.
- [ ] **RAG completo** que responde con citas (`rag.py`).
- [ ] **Hybrid search + re-ranking** (`retrieval_avanzado.py`).
- [ ] Técnicas de prompt engineering anti-alucinación aplicadas.
- [ ] **Evaluación con RAGAS** corriendo y entendida.
- [ ] (Opcional) Tracing con Langfuse (dashboard visto).
- [ ] Sé explicar la migración a producción (pgvector/Vertex/Bedrock/Vertex AI Search).
- [ ] Puedo **dibujar la arquitectura RAG de memoria**.
- [ ] Código commiteado.

Si todo está ✅ → **listo para el Manual 05B: Agentes y workflows (LangGraph).**

---

## 16. Troubleshooting

| Problema | Causa | Solución |
|---|---|---|
| Ollama "connection refused" | El servicio no corre | Abre la app Ollama / `ollama serve`; reintenta. |
| Embeddings muy lentos | CPU en vez de GPU | Verifica drivers NVIDIA; Ollama usa la GPU automáticamente. |
| `Activate.ps1` bloqueado | Política de ejecución | `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`. |
| "No encontré columna de narrativa" | Nombres distintos del CSV | Mira `df.columns` impreso y ajusta la detección. |
| Chroma da resultados raros | Índice viejo | Borra `chroma_db/` y re-indexa. |
| Respuestas inventadas | Prompt poco estricto / mal retrieval | Refuerza grounding; usa hybrid + re-ranking; baja temperatura a 0. |
| RAGAS falla al importar | Versión distinta | `pip show ragas`; ajusta imports según su doc. |
| Cross-encoder lento al descargar | Primera vez baja el modelo | Espera; queda cacheado para las próximas. |

---

## 17. Glosario

- **RAG:** generación aumentada con recuperación de tus documentos.
- **LLM:** modelo de lenguaje generativo.
- **Embedding:** vector que representa el significado de un texto.
- **Vector DB:** base de datos de embeddings (Chroma, pgvector, Pinecone).
- **Chunking:** partir documentos en fragmentos.
- **Retrieval:** recuperar los chunks relevantes a una consulta.
- **Búsqueda semántica vs BM25:** por significado vs por palabra clave.
- **Hybrid search:** combinar densa + BM25.
- **Re-ranking:** re-ordenar candidatos con un cross-encoder (más preciso).
- **Grounding:** obligar al LLM a responder solo desde el contexto.
- **Alucinación:** respuesta inventada, no fundamentada.
- **RAGAS:** framework de evaluación de RAG (faithfulness, relevancy, context precision/recall).
- **Tracing/observabilidad:** registrar y visualizar cada llamada (Langfuse/LangSmith).
- **Vertex AI Search / Bedrock KB:** RAG gestionado (no-code) en GCP / AWS.
- **pgvector / Vertex Vector Search:** vector DB en producción.

---

> **⬅️ Anterior:** [Manual 04 — Modelado de ML](./04_modelado_ml_fraude.md)
> **➡️ Siguiente:** Manual 05B — Agentes y workflows (LangGraph) _(en construcción)_
