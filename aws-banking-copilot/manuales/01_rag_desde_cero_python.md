# Manual 01 — RAG desde cero en Python (sin framework)

> **Objetivo:** Construir un sistema **RAG (Retrieval-Augmented Generation) mínimo, a mano, en Python puro** — sin LangChain, sin Knowledge Bases — para **entender de verdad cada pieza**: documentos → extracción → *chunking* → *embeddings* → vector store → *retrieval* top-k → prompt con contexto → **respuesta con citas**. Usaremos **Amazon Bedrock** solo como API de modelo (embeddings con Titan, generación con Claude), sin nada gestionado. Al terminar sabrás **explicar y defender** por qué RAG funciona, qué guarda una base vectorial, y cuándo usar búsqueda semántica, por palabra clave o híbrida.
>
> **Por qué este manual existe:** en una entrevista de *AWS GenAI/RAG Engineer* te van a preguntar el *porqué*, no solo el *cómo hacer clic*. Quien empieza por un framework aprende nombres de clases sin entender la arquitectura debajo. Aquí construyes la intuición que te diferencia.
>
> **Tiempo estimado:** 3–4 horas.
> **Requisito:** haber completado el [Manual 00](./00_entorno_aws.md) (Bedrock probado desde Python).

---

## 🖱️ / ⌨️ Cómo leer este manual

RAG es **código por naturaleza** — no hay "botón de RAG" en ninguna nube. Así que este manual es sobre todo Python. Para que sea lo más **visual e intuitivo** posible:

- 💻 **Trabaja en un notebook o en VS Code** con celdas, para **ver** los resultados intermedios (los chunks, los vectores, los puntajes). *Ver* cada paso es lo que construye la intuición.
- 🧪 Cada bloque de código imprime algo. **No avances sin mirar la salida** y entender qué pasó.
- 🐢 Vamos **lento y explicando el porqué**. Puedes copiar el código, pero **léelo línea por línea**: el valor no es tener el script, es entenderlo.

💡 **Consejo:** crea un archivo `retrieval/rag_scratch.py` (o un notebook `retrieval/rag_scratch.ipynb`) y ve pegando cada bloque en orden. Al final tendrás un RAG funcional de ~150 líneas que entiendes por completo.

---

## 📋 Tabla de contenido

1. [Qué es RAG y por qué (la intuición)](#1-que-es-rag)
2. [El pipeline completo (mapa mental)](#2-pipeline)
3. [Preparar el entorno y los documentos](#3-setup)
4. [Paso A — Extracción de texto](#4-extraccion)
5. [Paso B — Chunking (y por qué el tamaño importa)](#5-chunking)
6. [Paso C — Embeddings con Titan (qué es un vector)](#6-embeddings)
7. [Paso D — Vector store a mano con NumPy](#7-vectorstore)
8. [Paso E — Retrieval top-k (y por qué 5 ≠ 5 relevantes)](#8-retrieval)
9. [Paso F — Generación con citas (grounding)](#9-generacion)
10. [Paso G — Experimentos (chunk size, overlap, top-k, rechazo)](#10-experimentos)
11. [Semántica vs keyword vs híbrida (cuándo cada una)](#11-hibrida)
12. [Opcional — Vector store "de verdad" con Chroma](#12-chroma)
13. [✅ Checklist final](#13-checklist)
14. [🛟 Solución de problemas](#14-troubleshooting)
15. [📖 Glosario](#15-glosario)
16. [🔗 Fuentes (verificadas jul-2026)](#16-fuentes)

---

## 1. Qué es RAG

📖 **RAG (Retrieval-Augmented Generation):** darle al modelo, **junto con la pregunta, los fragmentos de texto relevantes** recuperados de *tus* documentos, para que responda **basándose en ellos** (y no en lo que "recuerde" de su entrenamiento).

**El problema que resuelve.** Un LLM solo:
- No conoce **tus** documentos privados (las políticas antifraude de tu banco).
- **Alucina:** inventa respuestas con seguridad cuando no sabe.
- Tiene conocimiento **congelado** en la fecha de su entrenamiento.

**La solución de RAG:** en vez de reentrenar el modelo (caro, lento), le **inyectas el contexto** en el momento de preguntar:

```
Pregunta del usuario
   +  fragmentos relevantes recuperados de TUS documentos
   ──────────────────────────────────────────────────────
   →  el modelo responde usando ESE contexto  →  respuesta con citas
```

💡 **La frase para la entrevista:** *"RAG separa el conocimiento (en una base recuperable, actualizable sin reentrenar) de la capacidad de razonar y redactar (el LLM). Recupero lo relevante y hago que el modelo responda anclado a esa evidencia, citando la fuente, para reducir alucinaciones."*

📖 **Embeddings vs modelo generativo — no los confundas (pregunta típica):**
- Un **modelo de embeddings** (Titan Embeddings) convierte un texto en un **vector de números** que captura su *significado*. Sirve para **buscar por similitud**. No genera texto.
- Un **modelo generativo** (Claude) **redacta** la respuesta. No busca.
- RAG usa **los dos**: embeddings para **encontrar**, el generativo para **responder**.

---

## 2. Pipeline

Hay **dos fases**. Grábate esta imagen mental:

```
FASE 1 — INDEXACIÓN (una vez, o cuando cambian los documentos)
  Documentos ─► Extraer texto ─► Chunking ─► Embeddings ─► Guardar en vector store
                                (trozos)     (vectores)     (índice)

FASE 2 — CONSULTA (cada pregunta del usuario)
  Pregunta ─► Embedding de la pregunta ─► Buscar top-k similares en el store
          ─► Construir prompt (pregunta + chunks) ─► LLM ─► Respuesta con citas
```

Todo lo que un servicio gestionado (Bedrock Knowledge Bases, Vertex AI Search) hace **por debajo** es exactamente esto. Por eso lo construimos a mano primero: cuando en el Manual 02 uses el gestionado, sabrás **qué está automatizando** y **qué puedes controlar**.

---

## 3. Setup

### 3.1 — Entorno de Python

Desde la raíz del proyecto AWS:
```bash
cd aws-banking-copilot
python3 -m venv .venv
source .venv/bin/activate
pip install boto3 numpy pypdf rank-bm25
export AWS_PROFILE=copilot      # tu perfil SSO del Manual 00
```
> 💡 Solo 4 librerías: `boto3` (AWS), `numpy` (matemática de vectores), `pypdf` (leer PDFs), `rank-bm25` (para el contraste keyword del §11). **Cero frameworks de RAG** — ese es el punto.

### 3.2 — Documentos de ejemplo

Crea la carpeta `ingestion/docs/` y dentro tres archivos Markdown que simulen políticas de un banco. Puedes copiarlos tal cual:

`ingestion/docs/politica_transferencias.md`
```markdown
# Política de Transferencias Internacionales

Las transferencias internacionales superiores a USD 10,000 requieren
verificación de identidad reforzada (KYC) y aprobación de un analista senior.
El plazo de acreditación es de 1 a 3 días hábiles. Las transferencias a países
en lista de alto riesgo (según la lista OFAC) quedan retenidas para revisión
manual del equipo de cumplimiento.
```

`ingestion/docs/tipologias_fraude.md`
```markdown
# Tipologías de Fraude Comunes

## Fraude de apropiación de cuenta (Account Takeover)
Ocurre cuando un tercero obtiene las credenciales del cliente. Señales:
cambio de dispositivo, cambio de contraseña seguido de una transferencia,
acceso desde una geolocalización inusual.

## Fraude del primer pago (First-Party Fraud)
El titular legítimo realiza una compra y luego la desconoce. Señales:
patrón repetido de contracargos, historial de disputas.

## Estafa de ingeniería social (Authorized Push Payment)
El cliente es engañado para autorizar él mismo una transferencia a un estafador.
El código de tipología interno es APP-2025.
```

`ingestion/docs/procedimiento_reclamos.md`
```markdown
# Procedimiento de Reclamos por Fraude

Cuando un cliente reporta una transacción no reconocida, el analista debe:
1. Congelar la tarjeta o cuenta afectada en menos de 30 minutos.
2. Abrir un caso con el código correspondiente a la tipología.
3. Si el monto supera USD 5,000, escalar al equipo de investigación (SAR).
El plazo regulatorio para resolver un reclamo es de 15 días hábiles.
```

> 💡 En un proyecto real, estos serían PDFs de cientos de páginas. Empezamos pequeño **para poder ver** cada paso. En el Manual 02 escalamos a S3 + Knowledge Bases.

---

## 4. Extracción

📖 **Extracción:** convertir cada documento (Markdown, PDF, HTML…) en **texto plano** que podamos procesar.

```python
from pathlib import Path
from pypdf import PdfReader

DOCS_DIR = Path("ingestion/docs")

def load_documents(docs_dir: Path) -> list[dict]:
    """Devuelve una lista de {source, text} por cada archivo."""
    docs = []
    for path in sorted(docs_dir.iterdir()):
        if path.suffix.lower() == ".md":
            text = path.read_text(encoding="utf-8")
        elif path.suffix.lower() == ".pdf":
            text = "\n".join(page.extract_text() or "" for page in PdfReader(str(path)).pages)
        else:
            continue
        docs.append({"source": path.name, "text": text})
    return docs

docs = load_documents(DOCS_DIR)
print(f"Cargados {len(docs)} documentos")
for d in docs:
    print(f"  - {d['source']}: {len(d['text'])} caracteres")
```

### ✅ Checkpoint 4
Ves los 3 documentos con su cantidad de caracteres. 

💡 **Detalle profesional:** guardamos `source` (el nombre del archivo) desde el minuto uno. Sin la **fuente**, luego no puedes **citar**. La trazabilidad empieza en la extracción.

🛟 *Un PDF devuelve texto vacío o basura:* es un PDF escaneado (imagen). Necesitaría **OCR** (ej. Amazon Textract). Lo mencionamos en el Manual 02; por ahora usa los `.md`.

---

## 5. Chunking

📖 **Chunking:** partir cada documento en **trozos (chunks)** más pequeños. Es el paso que **más impacta** la calidad del RAG.

**¿Por qué no meter el documento entero?**
- 📉 **Chunk demasiado grande:** metes mucho texto irrelevante junto al relevante → el modelo se distrae (**ruido**), gastas más **tokens** (más costo y latencia), y diluyes la señal.
- 📉 **Chunk demasiado pequeño:** cortas ideas a la mitad → un trozo pierde el **contexto** necesario para tener sentido (ej. "El plazo es de 15 días" sin decir de qué plazo habla).
- ✅ **El punto medio** depende de tus documentos. Un buen inicio: **300–800 caracteres** (o ~100–200 *tokens*) con **solapamiento (overlap)** de ~10–20%.

📖 **Overlap (solapamiento):** que cada chunk **repita** un poco del final del anterior. Así, una idea que cae justo en el borde no se pierde entre dos chunks.

Implementación mínima (por caracteres, con overlap):
```python
def chunk_text(text: str, chunk_size: int = 500, overlap: int = 80) -> list[str]:
    """Parte el texto en trozos de chunk_size con solapamiento."""
    chunks = []
    start = 0
    while start < len(text):
        end = start + chunk_size
        chunk = text[start:end].strip()
        if chunk:
            chunks.append(chunk)
        start += chunk_size - overlap        # avanzamos menos que el tamaño → overlap
    return chunks

# Aplicar a todos los documentos, conservando la fuente
def build_chunks(docs: list[dict], chunk_size=500, overlap=80) -> list[dict]:
    all_chunks = []
    for d in docs:
        for i, ch in enumerate(chunk_text(d["text"], chunk_size, overlap)):
            all_chunks.append({"source": d["source"], "chunk_id": i, "text": ch})
    return all_chunks

chunks = build_chunks(docs)
print(f"Total de chunks: {len(chunks)}\n")
print("Ejemplo de chunk:")
print(chunks[3]["text"])
```

### ✅ Checkpoint 5
Ves el total de chunks y el contenido de uno. **Léelo:** ¿tiene sentido por sí solo? ¿O quedó cortado raro? Esa observación es la que ajustarás con `chunk_size`/`overlap` en el §10.

💡 **Chunking avanzado (para saber que existe):** en vez de cortar por caracteres, se puede cortar por **estructura** (párrafos, títulos Markdown) o **semánticamente** (donde cambia el tema). Lo veremos con Bedrock KB en el Manual 02. Cortar por caracteres es el punto de partida honesto.

📖 **Caracteres vs tokens:** los modelos cuentan **tokens** (~4 caracteres o ~¾ de palabra en inglés). Aquí cortamos por caracteres por simplicidad; en producción se mide en tokens. La intuición es la misma.

---

## 6. Embeddings

📖 **Embedding:** un **vector** (lista de números, ej. 1024 de ellos) que representa el **significado** de un texto. Dos textos con significado parecido tienen vectores **cercanos** en el espacio. Eso es lo que permite "buscar por significado" en vez de por palabras exactas.

Usamos **Amazon Titan Text Embeddings V2** vía Bedrock:
```python
import boto3, json

bedrock = boto3.client("bedrock-runtime", region_name="us-east-1")
EMBED_MODEL_ID = "amazon.titan-embed-text-v2:0"

def embed(text: str) -> list[float]:
    resp = bedrock.invoke_model(
        modelId=EMBED_MODEL_ID,
        body=json.dumps({"inputText": text}),
    )
    return json.loads(resp["body"].read())["embedding"]

# Veamos qué es realmente un embedding
v = embed("transferencia internacional sospechosa")
print(f"Dimensión del vector: {len(v)}")
print(f"Primeros 5 números: {v[:5]}")
```

### ✅ Checkpoint 6
Imprime **Dimensión: 1024** y unos números. **Eso es un embedding:** un punto en un espacio de 1024 dimensiones. No es legible para ti, pero para la máquina, textos con significado parecido caen cerca.

💡 **Prueba la intuición** (opcional pero revelador):
```python
import numpy as np
def cos(a, b):  # similitud coseno: 1 = idéntico, 0 = sin relación
    a, b = np.array(a), np.array(b)
    return float(a @ b / (np.linalg.norm(a) * np.linalg.norm(b)))

base = embed("fraude por robo de credenciales")
print("similar :", cos(base, embed("apropiación de cuenta por credenciales robadas")))
print("distinto:", cos(base, embed("plazo de acreditación de transferencias")))
```
El primer par (mismo tema) da un coseno **más alto** que el segundo. **Ahí ves el significado convertido en geometría.**

⚠️ **Costo:** cada llamada a `embed()` consume tokens de Titan (muy barato, pero no gratis). Con 3 documentos es nada; cuando escales, cachea los embeddings (no recalcules lo que no cambió).

---

## 7. Vectorstore

📖 **Vector store / base vectorial:** donde **guardas los embeddings** de tus chunks para poder **buscar los más parecidos** a una consulta. Un servicio como OpenSearch, Pinecone o Chroma es, en esencia, esto **optimizado y a escala**. Para *entender qué guarda*, lo hacemos primero con NumPy.

```python
import numpy as np

# FASE 1 — Indexar: calcular el embedding de cada chunk y guardarlo
print("Indexando chunks (esto llama a Titan una vez por chunk)...")
for c in chunks:
    c["embedding"] = embed(c["text"])

# Matriz de embeddings (n_chunks x 1024) para buscar rápido
matrix = np.array([c["embedding"] for c in chunks])
print(f"Vector store en memoria: matriz {matrix.shape}")
```

### ✅ Checkpoint 7
Ves algo como `matriz (12, 1024)`: 12 chunks, cada uno un vector de 1024. **Eso es literalmente lo que guarda una base vectorial:** los vectores + el texto/metadata de cada chunk. Nada mágico.

💡 **Por qué los gestionados existen:** con 12 chunks, buscar con NumPy es instantáneo. Con **10 millones** de chunks, necesitas índices especializados (HNSW, IVF) que buscan "aproximadamente" pero muy rápido. Eso es lo que te dan OpenSearch/Pinecone. La **idea** es la que acabas de construir.

---

## 8. Retrieval

📖 **Retrieval:** dada una pregunta, calcular su embedding y traer los **k chunks más similares** del store.

```python
def cosine_similarities(query_vec: np.ndarray, matrix: np.ndarray) -> np.ndarray:
    q = query_vec / np.linalg.norm(query_vec)
    m = matrix / np.linalg.norm(matrix, axis=1, keepdims=True)
    return m @ q                      # un puntaje por chunk

def retrieve(question: str, k: int = 3) -> list[dict]:
    q_vec = np.array(embed(question))
    scores = cosine_similarities(q_vec, matrix)
    top_idx = np.argsort(scores)[::-1][:k]      # los k mayores
    results = []
    for rank, idx in enumerate(top_idx, 1):
        c = chunks[idx]
        results.append({**c, "score": float(scores[idx]), "rank": rank})
    return results

# Probémoslo
pregunta = "¿Qué hago si un cliente reporta una transacción que no reconoce?"
for r in retrieve(pregunta, k=3):
    print(f"[{r['rank']}] score={r['score']:.3f}  fuente={r['source']}#{r['chunk_id']}")
    print(f"    {r['text'][:120]}...\n")
```

### ✅ Checkpoint 8
Ves 3 chunks ordenados por `score`. El de mayor puntaje debería ser del `procedimiento_reclamos.md`. **¡Eso es retrieval semántico funcionando!** Notaste que no buscaste por palabras exactas ("reporta", "no reconoce") sino por **significado**.

💡 **La lección clave (pregunta de entrevista):** *"recuperar 5 fragmentos no significa que los 5 sean relevantes."* Mira los `score`: a veces el #3 tiene un puntaje bajo y en realidad es ruido. Por eso existen el **umbral de similitud** (descartar por debajo de X) y el **re-ranking** (Manual 03). Recuperar ≠ recuperar bien.

---

## 9. Generación

📖 **Generación aumentada:** construir un prompt que le dé al modelo **la pregunta + los chunks recuperados**, con instrucciones de **responder solo con ese contexto** y **citar la fuente**. Esto es lo que reduce alucinaciones.

```python
GEN_MODEL_ID = "<MODEL_ID_CLAUDE>"   # el que copiaste del Playground en el Manual 00

def build_prompt(question: str, retrieved: list[dict]) -> str:
    contexto = "\n\n".join(
        f"[Fuente: {r['source']}#{r['chunk_id']}]\n{r['text']}" for r in retrieved
    )
    return (
        "Eres un asistente de políticas de un banco. Responde la pregunta "
        "USANDO ÚNICAMENTE el contexto de abajo. Cita la fuente entre corchetes "
        "después de cada afirmación. Si el contexto no contiene la respuesta, "
        "di exactamente: 'No encuentro esa información en las políticas disponibles.'\n\n"
        f"### Contexto\n{contexto}\n\n### Pregunta\n{question}\n\n### Respuesta:"
    )

def generate(question: str, k: int = 3) -> str:
    retrieved = retrieve(question, k)
    prompt = build_prompt(question, retrieved)
    resp = bedrock.converse(
        modelId=GEN_MODEL_ID,
        messages=[{"role": "user", "content": [{"text": prompt}]}],
        inferenceConfig={"temperature": 0.0, "maxTokens": 500},
    )
    return resp["output"]["message"]["content"][0]["text"]

print(generate("¿Qué hago si un cliente reporta una transacción que no reconoce?"))
```

### ✅ Checkpoint 9
El modelo responde **basándose en tus documentos** y **cita** `[procedimiento_reclamos.md#...]`. **Acabas de construir un RAG completo, a mano, que entiendes de arriba a abajo.**

💡 **Decisiones profesionales en este prompt:**
- `temperature: 0.0` → respuestas **deterministas y fieles** (no queremos creatividad en políticas).
- La instrucción *"responde solo con el contexto"* + *"si no está, dilo"* → **grounding** y **rechazo correcto** (base de la evaluación del Manual 05 y de los Guardrails del Manual 04).
- **Citas obligatorias** → trazabilidad y confianza.

---

## 10. Experimentos

Ahora **experimenta** — aquí es donde se aprende de verdad. Cambia una variable a la vez y observa.

**a) Tamaño de chunk y overlap.** Reconstruye con distintos valores y repite una consulta:
```python
for size, ov in [(200, 30), (500, 80), (1200, 150)]:
    chunks = build_chunks(docs, chunk_size=size, overlap=ov)
    for c in chunks: c["embedding"] = embed(c["text"])
    matrix = np.array([c["embedding"] for c in chunks])
    top = retrieve("¿Cuál es el plazo para resolver un reclamo de fraude?", k=1)[0]
    print(f"size={size:>4} ov={ov:>3} → score={top['score']:.3f} | {top['text'][:80]}...")
```
👀 **Observa:** con chunks muy grandes el fragmento correcto puede "diluirse" (score más bajo o trae ruido); con muy pequeños puede perder contexto. Encuentra tu punto dulce **con datos, no con intuición**.

**b) top-k.** Prueba `k=1`, `k=3`, `k=8`. Más `k` = más contexto pero más ruido y tokens.

**c) Pregunta sin respuesta (rechazo).** Pregunta algo que **no está** en los documentos:
```python
print(generate("¿Cuál es la tasa de interés de las tarjetas de crédito?"))
```
✅ Debe responder *"No encuentro esa información…"*. **Que el sistema sepa decir "no sé" es tan importante como que acierte.** Un RAG que inventa es peligroso en banca.

### ✅ Checkpoint 10
Tienes una tabla comparando chunk sizes y confirmaste que el sistema **rechaza** lo que no está en el contexto. Ya puedes **explicar con evidencia** cómo afinaste el retrieval.

---

## 11. Híbrida

Tu retrieval actual es **100% semántico** (por significado). Pero a veces la búsqueda por **palabra clave exacta** gana. Entiende cuándo:

| Situación | Gana… | Por qué |
|---|---|---|
| "¿Qué es el fraude por ingeniería social?" | 🧠 **Semántica** | Sinónimos, paráfrasis, significado |
| "Busca el código de tipología **APP-2025**" | 🔤 **Keyword** | Un código exacto; el embedding puede "difuminarlo" |
| "Regla **OFAC** para transferencias" | 🔤/🧠 **Híbrida** | Sigla exacta + concepto |

📖 **Búsqueda por palabra clave (BM25):** puntúa por coincidencia de términos exactos (como un buscador clásico). Demostración del contraste:
```python
from rank_bm25 import BM25Okapi

corpus_tokens = [c["text"].lower().split() for c in chunks]
bm25 = BM25Okapi(corpus_tokens)

def keyword_search(query, k=3):
    scores = bm25.get_scores(query.lower().split())
    top = np.argsort(scores)[::-1][:k]
    return [(chunks[i]["source"], float(scores[i])) for i in top]

print("Semántica:", [(r["source"], round(r["score"],2)) for r in retrieve("código APP-2025", 3)])
print("Keyword  :", keyword_search("código APP-2025", 3))
```
👀 Para un **código exacto** como `APP-2025`, la keyword suele apuntar mejor.

📖 **Búsqueda híbrida:** combinar ambas y **fusionar** los rankings (técnica **RRF — Reciprocal Rank Fusion**). Es lo que mejora el retrieval en producción.

💡 **No lo implementamos a fondo aquí** — pertenece al Manual 03 (retrieval avanzado con OpenSearch, que soporta híbrida nativa). Pero ya **entiendes el porqué**, que es lo que te preguntarán.

---

## 12. Chroma

Tu store con NumPy es perfecto para aprender. Para un paso más "real" **en local**, existe **Chroma** (una base vectorial local, open source). Misma idea, con persistencia e índices:

```bash
pip install chromadb
```
```python
import chromadb
client = chromadb.Client()
col = client.create_collection("politicas")

# Indexar (Chroma guarda vectores + texto + metadata)
col.add(
    ids=[f"{c['source']}#{c['chunk_id']}" for c in chunks],
    embeddings=[c["embedding"] for c in chunks],
    documents=[c["text"] for c in chunks],
    metadatas=[{"source": c["source"]} for c in chunks],
)

# Consultar
res = col.query(query_embeddings=[embed("plazo para resolver un reclamo")], n_results=3)
for doc, meta in zip(res["documents"][0], res["metadatas"][0]):
    print(meta["source"], "→", doc[:80], "...")
```

💡 **Lo importante:** Chroma **no hace magia** — hace lo mismo que tu código NumPy, con índices y persistencia. Cuando en el Manual 02 uses **OpenSearch Serverless** (el equivalente gestionado y a escala en AWS), sabrás exactamente qué rol cumple.

🔁 **GCP:** el equivalente gestionado sería **Vertex AI Vector Search**.

---

## 13. Checklist

- [ ] Entiendo **qué problema resuelve RAG** y sé explicarlo en una frase.
- [ ] Distingo **embeddings** (buscar) de **modelo generativo** (responder).
- [ ] Cargué documentos **conservando la fuente** (para citar).
- [ ] Implementé **chunking** con overlap y entiendo el efecto del tamaño.
- [ ] Generé **embeddings** con Titan y vi qué es un vector.
- [ ] Construí un **vector store** con NumPy y sé qué guarda.
- [ ] Hice **retrieval top-k** y entiendo que "recuperar ≠ relevante".
- [ ] Generé respuestas **ancladas al contexto y con citas** (Claude, temp 0).
- [ ] Probé el **rechazo** de preguntas sin respuesta.
- [ ] **Experimenté** con chunk size / overlap / top-k y saqué conclusiones.
- [ ] Sé **cuándo** conviene semántica, keyword o híbrida.

Si marcaste todo: **entiendes RAG de verdad**, no solo de nombre. Ahora sí, el Manual 02 delega esto en **Bedrock Knowledge Bases + OpenSearch** — y sabrás qué automatiza cada pieza.

---

## 14. Troubleshooting

| Síntoma | Causa | Solución |
|---|---|---|
| `AccessDeniedException` en `embed`/`converse` | Modelo no habilitado | Habilita Titan Embeddings y Claude (Manual 00 §9) |
| `ValidationException` en el modelId | ID incorrecto | Usa el ID del "View API request" del Playground; embeddings usan `amazon.titan-embed-text-v2:0` |
| `Unable to locate credentials` | Sesión SSO caducó | `aws sso login --profile copilot` |
| Retrieval trae chunks irrelevantes | Chunk size/overlap malos o pocos docs | Ajusta §10; con más documentos mejora |
| El modelo alucina igual | Prompt débil | Refuerza "usa solo el contexto" + temperature 0 |
| Titan lento con muchos chunks | Una llamada por chunk | Cachea embeddings; en Manual 02 el gestionado lo hace por ti |

---

## 15. Glosario

- **RAG:** recuperar contexto relevante e inyectarlo al LLM para responder anclado a tus datos.
- **Chunk:** trozo de un documento.
- **Overlap:** solapamiento entre chunks para no perder contexto en los bordes.
- **Embedding:** vector que representa el significado de un texto.
- **Vector store:** almacén de embeddings para búsqueda por similitud.
- **Similitud coseno:** medida de cercanía entre dos vectores (1 = idénticos).
- **Top-k:** los k fragmentos más similares recuperados.
- **Grounding:** que la respuesta se base en el contexto recuperado.
- **BM25:** algoritmo de búsqueda por palabra clave.
- **Búsqueda híbrida / RRF:** combinar semántica + keyword y fusionar rankings.
- **Rechazo (refusal):** que el sistema diga "no sé" cuando el contexto no responde.

---

## 16. Fuentes

Verificadas el **21 de julio de 2026**:

- Amazon Titan Text Embeddings V2 (modelId, dimensiones, uso) — [docs.aws.amazon.com/bedrock/latest/userguide/titan-embedding-models.html](https://docs.aws.amazon.com/bedrock/latest/userguide/titan-embedding-models.html)
- Bedrock Converse API (`bedrock-runtime`, `converse`) — [docs.aws.amazon.com/bedrock/latest/userguide/converse-api.html](https://docs.aws.amazon.com/bedrock/latest/userguide/converse-api.html)
- boto3 `bedrock-runtime` (`invoke_model`, `converse`) — [boto3.amazonaws.com/v1/documentation/api/latest/reference/services/bedrock-runtime.html](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/bedrock-runtime.html)
- Chroma (base vectorial local) — [docs.trychroma.com](https://docs.trychroma.com/)

---

> **➡️ Siguiente manual:** `02_bedrock_kb_opensearch.md` — subir los documentos a **S3**, crear una **Bedrock Knowledge Base** con **OpenSearch Serverless** y **Titan Embeddings**, y comparar el RAG **gestionado** contra el que acabas de construir a mano. Incluye **control de costos** de OpenSearch (el susto #1 de la factura).
