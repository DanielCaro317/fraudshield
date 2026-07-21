# Manual 02 — Bedrock Knowledge Bases + vector store (OpenSearch / S3 Vectors)

> **Objetivo:** Reconstruir el RAG del Manual 01, pero ahora **gestionado por AWS**: subir los documentos a **Amazon S3**, crear una **Amazon Bedrock Knowledge Base** que se encarga sola de *chunking → embeddings → indexación → recuperación*, apoyada en un **vector store** (elegirás entre **OpenSearch Serverless** y **S3 Vectors**). Al final compararás el RAG **gestionado** contra el que hiciste **a mano** y sabrás exactamente **qué automatiza cada pieza** y **qué controlas tú**.
>
> **Lo que te diferencia aquí:** no solo "hacer clic para crear una KB", sino **elegir el vector store con criterio de costo/escala/latencia** — que es justo lo que un entrevistador senior de AWS quiere oír.
>
> **Tiempo estimado:** 2–3 horas.
> **Requisitos:** [Manual 00](./00_entorno_aws.md) (entorno + acceso a modelos) y [Manual 01](./01_rag_desde_cero_python.md) (entiendes RAG a mano).

> ⚠️ **AVISO DE COSTOS (léelo antes de empezar).** Este manual crea recursos que **pueden costar dinero real**. La opción clásica de **OpenSearch Serverless factura ~USD 174/mes aunque no la uses**. Sigue la sección de **elección de vector store (§4)** y **la de teardown (§11)** al pie de la letra. Con **S3 Vectors** o **scale-to-zero** el costo de aprender es de centavos.

---

## 🖱️ / ⌨️ Cómo leer este manual

Buenas noticias: crear una Knowledge Base es **muy visual** (casi todo por consola). El CLI/boto3 aparece para **probar** la KB desde código (lo que usarás en el proyecto). Vamos:

- 🖱️ **UI** para crear la KB y el vector store (clic por clic).
- ⌨️ **CLI/Python** para subir a S3 y para consultar la KB con `retrieve_and_generate`.
- ⚠️ **Recuadros de costo** donde haya que apagar/borrar algo.

---

## 📋 Tabla de contenido

1. [Qué es una Knowledge Base (RAG gestionado)](#1-que-es-kb)
2. [Qué automatiza vs tu RAG a mano (Manual 01)](#2-automatiza)
3. [Preparar los documentos con metadata](#3-metadata)
4. [Elegir el vector store (decisión de ingeniería + costos)](#4-vector-store)
5. [Paso A — Subir documentos a S3](#5-s3)
6. [Paso B — Crear la Knowledge Base](#6-crear-kb)
7. [Paso C — Sincronizar (ingesta) y qué pasa por debajo](#7-sync)
8. [Paso D — Probar en la consola](#8-probar-consola)
9. [Paso E — Probar por código (RetrieveAndGenerate)](#9-probar-codigo)
10. [Gestionado vs a mano: la comparación](#10-comparacion)
11. [⚠️ Teardown y control de costos (OBLIGATORIO)](#11-teardown)
12. [✅ Checklist final](#12-checklist)
13. [🛟 Solución de problemas](#13-troubleshooting)
14. [📖 Glosario](#14-glosario)
15. [🔗 Fuentes (verificadas jul-2026)](#15-fuentes)

---

## 1. Qué es KB

📖 **Amazon Bedrock Knowledge Base (KB):** el servicio **gestionado de RAG** de AWS. Le apuntas a unos documentos (en S3) y él se encarga **automáticamente** de: extraer texto, **chunking**, generar **embeddings** (con Titan), guardarlos en un **vector store**, y exponer una API para **recuperar** (`Retrieve`) o **recuperar + responder** (`RetrieveAndGenerate`) con citas.

Es exactamente el pipeline del Manual 01 — pero sin que tú escribas el bucle. Tú te concentras en **calidad, evaluación y seguridad** (lo que de verdad diferencia a un profesional).

🔁 **GCP:** el equivalente es **Vertex AI Search** / **Vertex AI RAG Engine**.

---

## 2. Automatiza

Pon lado a lado lo que hiciste a mano (Manual 01) y lo que ahora hace la KB. **Esta tabla es oro para la entrevista** ("¿qué automatiza un RAG gestionado?"):

| Etapa del pipeline | Manual 01 (a mano) | Knowledge Base (gestionado) |
|---|---|---|
| Extracción de texto | `pypdf` / leer archivo | Automática (incl. parsing avanzado / OCR opcional con FM parsing) |
| Chunking | Tu función `chunk_text` | Estrategia configurable (fixed, **semantic**, **hierarchical**, none) |
| Embeddings | Llamabas a Titan tú | Titan (u otro) automático en cada sync |
| Vector store | Matriz NumPy | OpenSearch Serverless / **S3 Vectors** / Aurora… |
| Retrieval top-k | Tu función `retrieve` | API `Retrieve` (con filtros por metadata) |
| Generación + citas | Tu `build_prompt` + Converse | API `RetrieveAndGenerate` (citas incluidas) |
| Reindexar al cambiar docs | Recorrías todo otra vez | **Sync** incremental |

💡 **La conclusión que debes poder decir:** *"El gestionado me quita el trabajo repetitivo de ingestión y me da citas y sync incremental; a cambio pierdo control fino sobre el prompt y el ranking, que recupero con la API `Retrieve` + mi propia generación (Manual 03)."*

---

## 3. Metadata

Un RAG profesional no solo guarda texto: guarda **metadata** por chunk (fecha, producto, país, tipo de documento) para poder **filtrar** en la búsqueda ("solo políticas vigentes de Colombia"). Bedrock KB lee la metadata desde un archivo `.metadata.json` **al lado** de cada documento en S3.

Para cada documento, crea un archivo hermano. Ejemplo para `procedimiento_reclamos.md`:

`ingestion/docs/procedimiento_reclamos.md.metadata.json`
```json
{
  "metadataAttributes": {
    "tipo": "procedimiento",
    "producto": "fraude",
    "pais": "CO",
    "vigente_desde": "2025-01-01"
  }
}
```
Haz lo mismo para los otros dos (`politica_transferencias.md.metadata.json`, `tipologias_fraude.md.metadata.json`), ajustando `tipo`.

💡 **Por qué importa:** en el Manual 03 filtrarás por estos campos (`pais = CO`), y en el Manual 04 (Guardrails) y 08 (multi-tenant) el control de acceso por metadata es clave. Sembramos la semilla ahora.

---

## 4. Vector store

Aquí tomas una **decisión de ingeniería**, no un clic al azar. Bedrock KB soporta varios vector stores. Los que importan:

| Vector store | Costo (aprender) | Cuándo usarlo | Nota |
|---|---|---|---|
| **S3 Vectors** ⭐ | **Muy bajo** (pagas por uso, ~90% más barato) | Volúmenes grandes, recuperación **poco frecuente**, tolera latencia sub-100 ms | **Recomendado para este proyecto** por costo. GA 2025 |
| **OpenSearch Serverless (clásico)** | ~**USD 174/mes** aunque esté idle (dev-test, 0.5+0.5 OCU) | Producción, baja latencia, búsqueda híbrida nativa | Es **el keyword** que piden las vacantes "Bedrock + OpenSearch". **Bórralo al terminar** |
| **OpenSearch Serverless NextGen** | **Scale-to-zero** (deja de facturar tras 10 min idle) | Igual que arriba pero sin pagar en reposo | GA may-2026. Si está disponible, mejor que el clásico |
| **Aurora PostgreSQL Serverless (pgvector)** | Bajo-medio | Ya usas Postgres / SQL + vectores juntos | pgvector gestionado |
| **Pinecone / Redis / MongoDB** | Externos | Si el equipo ya los usa | Fuera de alcance aquí |

### 🎯 Mi recomendación para ti

Haz el proyecto **dos veces conceptualmente**, pero construye una:

- **Para aprender y dejar corriendo barato → S3 Vectors.** Lo dejas montado entre sesiones sin miedo a la factura.
- **Para poder decir "he usado OpenSearch con Bedrock" (keyword de CV) → monta OpenSearch Serverless UNA vez**, pruébalo, y **bórralo el mismo día** (§11). Así tienes la experiencia y la anécdota sin pagar $174.

> 💬 **Frase de entrevista:** *"Elijo el vector store por costo, escala y latencia: S3 Vectors para grandes volúmenes con recuperación poco frecuente y ahorro de costo; OpenSearch Serverless cuando necesito baja latencia y búsqueda híbrida en producción; Aurora si ya tengo Postgres. No es 'siempre OpenSearch'."*

En los pasos siguientes uso **"Quick create"**, que te deja elegir el store. Donde diga `<VECTOR_STORE>`, aplica tu elección.

---

## 5. S3

📖 **S3 bucket:** una "carpeta" en la nube donde viven tus documentos. La KB los lee de ahí.

🖱️ **Por la Consola (UI):**
1. Busca **S3** → **Create bucket**.
2. Nombre **único global**: `banking-copilot-docs-<tu-sufijo>` (ej. tu iniciales+números). Región **us-east-1**.
3. Deja el resto por defecto (bloqueo de acceso público **activado** — bien). **Create bucket**.
4. Entra al bucket → **Upload** → sube la carpeta `ingestion/docs/` completa (los `.md` **y** los `.metadata.json`).

⌨️ **Equivalente en CLI** (más rápido):
```bash
aws s3 mb s3://banking-copilot-docs-<tu-sufijo> --region us-east-1
aws s3 cp ingestion/docs/ s3://banking-copilot-docs-<tu-sufijo>/docs/ --recursive
aws s3 ls s3://banking-copilot-docs-<tu-sufijo>/docs/
```

### ✅ Checkpoint 5
`aws s3 ls` (o la consola) muestra tus 3 `.md` y sus 3 `.metadata.json` en el bucket.

🔁 **GCP:** S3 ≈ **Cloud Storage** (`gsutil cp`).

---

## 6. Crear KB

🖱️ **Por la Consola (UI):**
1. Ve a **Amazon Bedrock** → panel izquierdo → **Knowledge Bases** → **Create** → **Knowledge Base with vector store**.
2. **Detalles:**
   - Nombre: `kb-banking-policies`.
   - **IAM permissions:** deja **"Create and use a new service role"** (AWS crea el rol con los permisos correctos).
3. **Data source:** elige **Amazon S3**.
   - **S3 URI:** apunta a `s3://banking-copilot-docs-<tu-sufijo>/docs/`.
4. **Parsing / Chunking:** para empezar deja **Default chunking** (fixed-size ~300 tokens).
   - 💡 Más adelante prueba **Semantic** o **Hierarchical** y compara calidad (eso es afinar RAG con criterio).
5. **Embeddings model:** **Titan Text Embeddings V2**.
6. **Vector store:** **Quick create a new vector store** → elige tu `<VECTOR_STORE>`:
   - **S3 Vectors** (recomendado por costo), **o**
   - **Amazon OpenSearch Serverless** (keyword de CV; recuerda borrarlo).
7. Revisa y **Create Knowledge Base**. Espera unos minutos (crea el store + el rol).

### ✅ Checkpoint 6
La KB aparece en estado **Available** y con un **Knowledge base ID** (algo como `ABCD1234`). **Anótalo**, lo usarás en código.

⌨️ **Nota CLI/boto3:** crear la KB por API se hace con `bedrock-agent` (`create_knowledge_base`, `create_data_source`) y **requiere ARNs de rol y de colección** — es verboso. Por eso la creación va por **UI** (más robusta ante cambios). El **consumo** sí lo haremos por código (§9). Los nombres de API que debes conocer: `bedrock-agent` (gestión) y `bedrock-agent-runtime` (consulta).

🛟 *Falla la creación del vector store:* suele ser permisos o límites de la cuenta. Revisa que el rol de servicio se creó y que tu región tiene el store elegido.

---

## 7. Sync

La KB no indexa sola: hay que **sincronizar** la fuente de datos para que lea S3, haga chunking + embeddings y llene el vector store.

🖱️ **Por la Consola (UI):**
1. Entra a tu KB → sección **Data source** → selecciona la fuente S3 → **Sync**.
2. Espera a que el estado del **sync job** pase a **Completed**. Verás cuántos archivos ingirió.

📖 **Qué pasó por debajo (lo que hiciste a mano en el Manual 01):** leyó cada archivo, lo partió en chunks según la estrategia, calculó su embedding con Titan, y guardó vector+texto+metadata en el store. **Sync incremental:** si luego cambias un documento y re-sincronizas, solo reprocesa lo que cambió.

### ✅ Checkpoint 7
El sync job dice **Completed** con 3 archivos fuente procesados.

🛟 *Sync falla o ingiere 0:* revisa que el S3 URI apunte a la carpeta correcta y que el rol de servicio tenga permiso de lectura al bucket. Los `.metadata.json` **no** cuentan como documentos: acompañan a su `.md`.

---

## 8. Probar consola

🖱️ En tu KB, arriba a la derecha hay un panel **"Test Knowledge Base"**:
1. **Selecciona un modelo** de generación (un **Claude**).
2. Escribe: *"¿Cuál es el plazo para resolver un reclamo de fraude?"* → **Run**.
3. Debe responder **con la respuesta correcta y mostrar las citas** (de qué documento salió).
4. Prueba el toggle **"Generate responses"** on/off:
   - **Off** = solo **Retrieve** (te muestra los chunks recuperados, sin redactar).
   - **On** = **RetrieveAndGenerate** (recupera + redacta + cita).

### ✅ Checkpoint 8
La KB responde en la consola **con citas**. Prueba también una pregunta **fuera de los documentos** y observa cómo se comporta (esto lo endureceremos con Guardrails en el Manual 04).

---

## 9. Probar código

Ahora lo que usarás en el proyecto: consultar la KB desde Python con **`bedrock-agent-runtime`**.

```python
import boto3

agent = boto3.client("bedrock-agent-runtime", region_name="us-east-1")

KB_ID = "<TU_KB_ID>"          # del Checkpoint 6
# ARN del modelo de generación (Claude). Formato base:
# arn:aws:bedrock:us-east-1::foundation-model/<MODEL_ID>
# (o un ARN de inference profile si el modelo lo exige; cópialo del Playground)
MODEL_ARN = "arn:aws:bedrock:us-east-1::foundation-model/<MODEL_ID_CLAUDE>"

def ask_kb(question: str) -> dict:
    return agent.retrieve_and_generate(
        input={"text": question},
        retrieveAndGenerateConfiguration={
            "type": "KNOWLEDGE_BASE",
            "knowledgeBaseConfiguration": {
                "knowledgeBaseId": KB_ID,
                "modelArn": MODEL_ARN,
            },
        },
    )

resp = ask_kb("¿Cuál es el plazo para resolver un reclamo de fraude?")
print("RESPUESTA:\n", resp["output"]["text"], "\n")
print("CITAS:")
for cita in resp["citations"]:
    for ref in cita["retrievedReferences"]:
        loc = ref["location"].get("s3Location", {}).get("uri", "?")
        print("  -", loc)
```

### ✅ Checkpoint 9
El script imprime la respuesta **y** las URIs de S3 de los documentos citados. **Ese es tu RAG gestionado funcionando desde código**, con trazabilidad de fuentes.

💡 **Compara con el Manual 01:** allá tú construías el prompt y las citas; aquí `RetrieveAndGenerate` lo hace. En el **Manual 03** usarás `Retrieve` (solo recuperar) + tu propia generación con `Converse` para **recuperar el control** del prompt, el ranking y la lógica de rechazo.

---

## 10. Comparacion

| Criterio | RAG a mano (Manual 01) | KB gestionada (Manual 02) |
|---|---|---|
| Velocidad de montaje | Lento (todo tú) | **Rápido** (clics + sync) |
| Control del prompt/ranking | **Total** | Limitado (lo abre `Retrieve` en Manual 03) |
| Chunking avanzado (semantic/hierarchical) | Tú lo programas | **Incluido** como opción |
| Citas y sync incremental | Tú los implementas | **Incluidos** |
| Filtros por metadata | Tú los programas | **Nativos** (Manual 03) |
| Costo | Solo tokens | Tokens + **vector store** |
| Ideal para | Entender / prototipos | **Producción** y escala |

💬 **Frase de entrevista:** *"Sé implementar RAG a mano con boto3 para entender y controlar cada componente, y sé usar Knowledge Bases cuando quiero velocidad, sync incremental y citas gestionadas. Elijo según cuánto control fino necesito."*

---

## 11. Teardown

⚠️ **ESTA SECCIÓN NO ES OPCIONAL.** Si montaste **OpenSearch Serverless clásico**, se factura ~**USD 174/mes** aunque no lo toques. Bórralo al terminar la sesión.

**Qué borrar (en orden):**

1. **La Knowledge Base** (Bedrock → Knowledge Bases → tu KB → **Delete**). 
2. **El vector store:**
   - **OpenSearch Serverless:** ve a **OpenSearch Service → Serverless → Collections** y **borra la colección** que creó la KB (nombre parecido a `bedrock-knowledge-base-...`). También revisa **Security policies** asociadas.
   - **S3 Vectors:** su costo es por uso; puedes dejarlo, pero si quieres limpiar, borra el **vector bucket** en S3.
   - **Aurora:** borra el cluster.
3. **(Opcional) El bucket S3 de documentos** — su costo es mínimo; puedes dejarlo para el próximo manual.

⌨️ **Verifica que no queda nada caro encendido:**
```bash
# Colecciones de OpenSearch Serverless (no debería quedar ninguna de la KB):
aws opensearchserverless list-collections --region us-east-1
```

✅ **Confirma en AWS Budgets / Cost Explorer** al día siguiente que no hay cargos crecientes.

💡 **Estrategia recomendada:** si vas a iterar varios días, **usa S3 Vectors** y evitas todo este baile de borrar/recrear. Reserva OpenSearch para una sesión puntual "para el CV".

### ✅ Checkpoint 11
`list-collections` no muestra colecciones de la KB (o usaste S3 Vectors). **Duermes tranquilo.**

---

## 12. Checklist

- [ ] Entiendo qué **automatiza** una KB frente a mi RAG a mano.
- [ ] Preparé documentos **con metadata** (`.metadata.json`).
- [ ] **Elegí el vector store con criterio** de costo/escala/latencia (y sé justificarlo).
- [ ] Subí los documentos a **S3**.
- [ ] Creé la **Knowledge Base** (rol de servicio, data source, chunking, Titan, vector store).
- [ ] **Sincronicé** e ingirió los documentos.
- [ ] Probé la KB en **consola** (con citas).
- [ ] Probé la KB por **código** (`retrieve_and_generate` + citas).
- [ ] Sé **comparar** gestionado vs a mano en una frase.
- [ ] **Borré** OpenSearch Serverless (o usé S3 Vectors) y **verifiqué** que no hay cargos.

Si marcaste todo: tienes un **RAG gestionado en Bedrock, con criterio de costos**. El Manual 03 abre la caja: `Retrieve` vs `RetrieveAndGenerate`, filtros por metadata y control del prompt.

---

## 13. Troubleshooting

| Síntoma | Causa | Solución |
|---|---|---|
| KB no pasa a **Available** | Error creando el store/rol | Revisa permisos y límites; reintenta con otro store |
| Sync ingiere **0** documentos | S3 URI mal o permisos | Apunta a la carpeta correcta; el rol necesita leer el bucket |
| `retrieve_and_generate` da `AccessDenied` | Falta permiso o modelo no habilitado | Habilita Claude (Manual 00 §9); tu identidad necesita `bedrock:Retrieve*` |
| `ValidationException` en `modelArn` | ARN mal formado | Usa `arn:aws:bedrock:us-east-1::foundation-model/<MODEL_ID>` o el ARN del inference profile |
| Respuestas pobres | Chunking por defecto no ideal | Prueba **Semantic/Hierarchical**; re-sync |
| **Factura crece** | OpenSearch Serverless encendido | **§11 Teardown** ya mismo |

---

## 14. Glosario

- **Knowledge Base (KB):** RAG gestionado de Bedrock.
- **Data source:** origen de documentos (S3) que la KB ingiere.
- **Sync / ingestion job:** proceso que lee, chunkea, embebe e indexa.
- **Vector store:** dónde se guardan los embeddings (OpenSearch Serverless, S3 Vectors, Aurora…).
- **OCU (OpenSearch Compute Unit):** unidad de cómputo/costo de OpenSearch Serverless.
- **S3 Vectors:** vector store serverless de bajo costo integrado con KB.
- **Metadata (`.metadata.json`):** atributos por documento para filtrar en la búsqueda.
- **Retrieve:** API que solo recupera chunks.
- **RetrieveAndGenerate:** API que recupera + redacta + cita.
- **bedrock-agent / bedrock-agent-runtime:** clientes boto3 para gestionar / consultar KBs.

---

## 15. Fuentes

Verificadas el **21 de julio de 2026**:

- Crear una Knowledge Base conectando una fuente — [docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-create.html](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-create.html)
- Opciones de vector store para KB — [docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-setup.html](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-setup.html)
- S3 Vectors con Bedrock Knowledge Bases — [docs.aws.amazon.com/AmazonS3/latest/userguide/s3-vectors-bedrock-kb.html](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-vectors-bedrock-kb.html) · [aws.amazon.com/s3/features/vectors/](https://aws.amazon.com/s3/features/vectors/)
- OpenSearch Serverless: capacidad/OCU y costos — [aws.amazon.com/opensearch-service/pricing/](https://aws.amazon.com/opensearch-service/pricing/) · [scale-to-zero](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/serverless-scale-to-zero.html)
- Elegir base vectorial para RAG (guía prescriptiva) — [docs.aws.amazon.com/prescriptive-guidance/latest/choosing-an-aws-vector-database-for-rag-use-cases/vector-db-options.html](https://docs.aws.amazon.com/prescriptive-guidance/latest/choosing-an-aws-vector-database-for-rag-use-cases/vector-db-options.html)
- `retrieve_and_generate` (boto3) — [boto3.amazonaws.com/v1/documentation/api/latest/reference/services/bedrock-agent-runtime.html](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/bedrock-agent-runtime.html)

---

> **➡️ Siguiente manual:** `03_retrieve_generate_boto3.md` — abrir la caja del RAG gestionado: **`Retrieve` vs `RetrieveAndGenerate`**, **filtros por metadata** (`pais = CO`), construir tu propio prompt con los chunks recuperados y controlar la **lógica de rechazo** y las **citas**. El punto donde recuperas control sin perder lo gestionado.
