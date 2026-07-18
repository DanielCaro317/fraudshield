# 🎤 Preparación — Entrevista Técnica Proxify (Senior AI Engineer)

> **Objetivo:** Llegar a la entrevista técnica final de Proxify con respuestas **estructuradas, concretas y con herramientas nombradas**, en inglés, respaldadas por el proyecto **FraudShield**. Corrige los 3 gaps que se vieron en el screening (testing, CI/CD, seguridad) + la comunicación.
>
> **Cómo usar este doc:** Practica en voz alta **en inglés**. Memoriza la *estructura* (no el texto literal). Grábate, escúchate, repite. Meta: responder cada pregunta en **60–90 segundos**.
>
> **Relacionado:** [`PLAN_APRENDIZAJE_PROXIFY_AI_ENGINEER.md`](./PLAN_APRENDIZAJE_PROXIFY_AI_ENGINEER.md) · [`manuales/`](./manuales/README.md)

---

## 📑 Índice
1. [Reglas de comunicación (el meta-gap)](#1-comunicación)
2. [Tu pitch de 90 segundos (memorizar)](#2-pitch)
3. [Cheat sheet de tooling por tema](#3-cheatsheet)
4. [Los 3 gaps con guion ganador](#4-gaps)
5. [Banco de preguntas técnicas senior (con respuestas)](#5-banco)
6. [Preguntas de diseño/arquitectura (system design de IA)](#6-design)
7. [Trampas y cómo evitarlas](#7-trampas)
8. [Plan de ensayo (1 semana antes)](#8-ensayo)

---

## 1. Comunicación

> En el screening: respuestas largas, poco estructuradas, "sorry for my English", y "I don't remember" + nombres de tools que no salieron. Esto se corrige con método.

**Reglas:**
1. **Estructura STAR / Problema-Solución-Resultado.** Nunca improvises sin esqueleto.
2. **Nombra herramientas concretas** en cada respuesta. La vaguedad mata ("pytest", "RAGAS", "GitHub Actions", "pgvector", "Secret Manager"...).
3. **60–90 segundos** por respuesta. Si quieres profundizar: *"I can go deeper if useful."*
4. **Nunca digas "I don't remember".** Cámbialo por: *"I typically use X for that"* o *"The approach I'd take is…"*.
5. **No te disculpes por el inglés.** Habla más lento, frases cortas, claras. La confianza pesa más que la perfección.
6. **Si no sabes algo:** *"I haven't used that specific tool, but it's similar to X, and I'd approach it by…"*. Demuestra razonamiento + curva de aprendizaje.

**Muletilla útil para ganar tiempo (en inglés):**
> *"Good question. Let me structure my answer in two parts…"*

---

## 2. Pitch

> Memoriza esta versión estructurada de tu background. Reemplaza la divagación del screening.

> *"I'm an AI/ML engineer with experience building **end-to-end AI systems in production**, especially in the **banking / fraud domain**. My flagship project is a fraud-detection platform where I built three things: (1) a **data pipeline** ingesting millions of transactions into a data warehouse with dbt and Airflow; (2) **ML models** for fraud detection — XGBoost on highly **imbalanced data**, evaluated with **AUC-PR** and explained with **SHAP**; and (3) a **RAG system** plus an **agentic workflow** that lets fraud analysts query case narratives in natural language and auto-draft suspicious-activity reports. I deploy with **FastAPI + Docker on Cloud Run**, with **CI/CD in GitHub Actions including evaluation gates (RAGAS)**, **guardrails** for the LLM, and **observability** with Langfuse. I work mostly on **GCP**, and I'm comfortable mapping it to **AWS** (S3, Bedrock, SageMaker, ECS)."*

💡 Esto cubre, en 90s: producción, dominio (fraude/banca), data eng, ML, RAG, **agentes**, deploy, **CI/CD con eval-gates**, **seguridad**, observabilidad y **multi-cloud**. Todo lo que Proxify quiere oír.

---

## 3. Cheatsheet

> Ten estos nombres en la punta de la lengua. Si te preguntan por un área, **suelta 2–3 herramientas**.

| Área | Herramientas que debes nombrar |
|---|---|
| Lenguaje/API | Python, **FastAPI**, Pydantic, Uvicorn |
| LLMs | **OpenAI, Anthropic (Claude)**, open-source (Llama 3), **Ollama** (local) |
| Frameworks LLM | **LangChain, LangGraph, LlamaIndex** |
| RAG / retrieval | **embeddings**, **hybrid search (dense + BM25)**, **re-ranking** (cross-encoder, Cohere Rerank), chunking |
| Vector DBs | **pgvector**, **Pinecone**, **Weaviate**, **Qdrant**, **Chroma**, FAISS |
| Evaluación LLM | **RAGAS** (faithfulness, answer relevancy, context precision/recall), **LLM-as-judge**, golden datasets |
| Observabilidad LLM | **LangSmith**, **Langfuse** |
| Testing | **pytest**, mocking de LLM, **Locust/k6** (carga) |
| MLOps | **MLflow**, **Weights & Biases (W&B)**, model registry |
| CI/CD | **GitHub Actions**, eval-gates, Docker build, **Artifact Registry/ECR** |
| Contenedores/orquestación | **Docker**, **Kubernetes (EKS/GKE)** |
| Cloud | **GCP** (Cloud Run, Vertex AI, BigQuery), **AWS** (Bedrock, SageMaker, Lambda, ECS, S3) |
| Seguridad IA | **OWASP LLM Top 10**, **prompt injection**, **guardrails** (Llama Guard, NeMo Guardrails), **PII** (Presidio/DLP), Secret Manager |
| Fine-tuning | **LoRA/QLoRA**, **PEFT**, cuantización |

---

## 4. Gaps

> Las 3 preguntas que fallaste en el screening. Domina estos guiones.

### 🔴 4.1 — "How do you test your back-end APIs and AI pipelines? Which frameworks?"
**Estructura: 3 capas.**
> *"I test in three layers. **First, code and API**: `pytest` for unit and integration tests, and I **mock the LLM calls** to make tests deterministic. **Second, the AI/LLM layer**: I run **RAGAS** to measure **faithfulness, answer relevancy, and context precision/recall** against a **golden dataset**, plus **LLM-as-a-judge** for qualitative criteria, to catch **hallucinations**. **Third, performance**: I measure **latency — including time-to-first-token — and throughput** with **Locust**. And critically, these evals run **in CI as a gate**: if quality drops below a threshold, the pipeline fails."*

### 🔴 4.2 — "Have you set up CI/CD pipelines? What tools?"
> *"Yes, with **GitHub Actions**. On every pull request the pipeline runs **lint (ruff/black) → tests (pytest) → AI evals (RAGAS) → Docker build → push to Artifact Registry**. On merge to `main`, it **deploys automatically (CD)** to **Cloud Run** — or **ECS** on AWS. I **version prompts and models**, and promote dev→prod with an approval step. I distinguish three layers: **DevOps** for infra and app, **MLOps** for the model lifecycle, and **LLMOps** for prompts, evaluations, and guardrails."*

💡 **Aclara los términos** (en el screening se mezclaron): DevOps ≠ MLOps ≠ LLMOps.

### 🔴 4.3 — "What security/privacy practices do you follow with sensitive data?"
> *"I follow the **OWASP Top 10 for LLM applications** as a framework. Concretely: **secrets in Secret Manager**, never in code; **IAM with least privilege**; **PII detection and masking** with **Cloud DLP** or **Microsoft Presidio**; **guardrails** with **Llama Guard / NeMo Guardrails** plus input/output validation to defend against **prompt injection**; **rate limiting and cost limits** on the API; and encryption in transit and at rest. In the RAG, the model **answers only from retrieved context and cites its sources**, which reduces both data leakage and hallucinations."*

---

## 5. Banco

### Q1 — "RAG vs fine-tuning vs prompting — when do you use each?"
> *"**Prompting** first — cheapest, fastest, when the base model already knows the task. **RAG** when the model needs **external or fresh knowledge** it wasn't trained on — like our fraud case narratives — without retraining. **Fine-tuning** when I need to change **behavior, format, or style consistently**, or specialize a smaller/cheaper model for a narrow task — for example, a small model that classifies complaints by fraud type. Often I combine: a fine-tuned small model **inside** a RAG pipeline. I decide based on cost, latency, and whether the gap is knowledge (RAG) or behavior (fine-tuning)."*

### Q2 — "Explain a RAG architecture you built."
> *"Documents → **chunking** → **embeddings** → stored in a **vector DB (pgvector)**. At query time: embed the query, do **hybrid retrieval (dense + BM25)**, **re-rank** the top results with a cross-encoder, build an **augmented prompt** with the top-k chunks, and the LLM generates an answer **grounded in and citing** those chunks. I evaluate it with **RAGAS** and trace it with **Langfuse**. For fraud, this lets an analyst ask 'what patterns appear in unauthorized-transfer complaints?' and get a cited answer."*

### Q3 — "How do you design an AI agent? How do you handle errors and loops?"
> *"I model the agent as a **state graph with LangGraph**: nodes are steps (reason, call a tool, reflect), edges are transitions, and I allow **cycles** for retries. The agent uses **tool/function calling** — e.g., query BigQuery, score a transaction, search complaints via RAG, draft a SAR. I handle errors with **try/fallback nodes**, **max-iteration limits** to avoid infinite loops, **timeouts**, and **human-in-the-loop** checkpoints for high-risk actions. I trace every step in Langfuse to debug."*

### Q4 — "How do you know your RAG is hallucinating?"
> *"**Faithfulness** in RAGAS measures whether the answer is grounded in the retrieved context — low faithfulness = hallucination. I also check **context precision/recall** to see if retrieval brought the right evidence. In production I log traces in **Langfuse** and use **LLM-as-judge** on a sample, plus user feedback. The structural defense is forcing the model to **answer only from context and cite sources**."*

### Q5 — "How do you scale an LLM system in production?"
> *"Several levers: **caching** (embeddings and frequent responses), **streaming** tokens for perceived latency, **async** request handling in FastAPI, **batching** embeddings, and **autoscaling** — Cloud Run/serverless for spiky traffic, or **Kubernetes (GKE/EKS)** when I need fine-grained control. I also pick the **right model size** per task and add a **semantic cache**. I monitor latency p95, cost per request, and token usage."*

### Q6 — "Why hybrid search and re-ranking?"
> *"Pure dense (embedding) search can miss exact keywords — IDs, names, codes — and pure keyword (BM25) misses semantics. **Hybrid** combines both via **Reciprocal Rank Fusion**. Then a **re-ranker** (cross-encoder) re-scores the top candidates with deeper query-document attention, pushing the most relevant chunks to the top. This measurably improves **context precision**, which directly improves answer quality."*

### Q7 — "How do you evaluate and compare models / track experiments?"
> *"**MLflow** or **Weights & Biases** — I log params, metrics, and artifacts per run, compare runs, and register the **champion model** in a registry. For LLM features specifically, the 'experiment' is often a prompt or retrieval change, so I track **RAGAS scores** per version and gate releases on them."*

### Q8 — "Vector databases — which and why?"
> *"Depends on scale and ops. **pgvector** when I already have Postgres and want one less system — great for our case. **Pinecone** for fully-managed, large scale. **Qdrant/Weaviate** for self-hosted with rich filtering and hybrid search. **Chroma/FAISS** for local prototyping. I choose by scale, filtering needs, managed vs self-hosted, and cost."*

### Q9 — "How do you handle imbalanced data in fraud detection?" (tu dominio)
> *"Fraud is ~0.1% of transactions, so **accuracy is useless** — I optimize **AUC-PR, recall and precision**, and reason about the **cost of false negatives vs false positives**. Techniques: **class weights / `scale_pos_weight`** in XGBoost, **resampling (SMOTE/undersampling)** via imbalanced-learn, threshold tuning, and **SHAP** to explain flags to the risk team."*

### Q10 — "How do you defend against prompt injection?"
> *"Input/output **guardrails** (Llama Guard / NeMo), **separating system instructions from user content**, **never executing tool calls blindly** — validating and constraining them, allow/deny lists, and **least-privilege tools** so even a successful injection can't do damage. For **indirect injection** (malicious content inside retrieved docs), I sanitize and constrain what the model can act on. It's OWASP LLM01."*

---

## 6. Design

> Para senior, esperan que diseñes un sistema en voz alta. Practica este formato: **requisitos → componentes → flujo de datos → escalado → evaluación → seguridad → trade-offs**.

**Pregunta tipo:** *"Design an AI assistant that answers questions over a company's internal documents."*

**Esqueleto de respuesta (en voz alta):**
1. **Requirements:** volumen de docs, usuarios concurrentes, latencia objetivo, sensibilidad de datos, ¿necesita acciones (agente) o solo Q&A (RAG)?
2. **Ingestion:** loaders → chunking → embeddings → vector DB (pgvector/Pinecone). Pipeline incremental.
3. **Retrieval:** hybrid search + re-ranking + metadata filtering.
4. **Generation:** LLM (Claude/OpenAI) con prompt grounded + citations; structured output si aplica.
5. **Agentic (si aplica):** LangGraph con tools, human-in-the-loop.
6. **Serving:** FastAPI + Docker + Cloud Run/EKS, streaming, caching.
7. **Eval:** RAGAS + golden set + LLM-judge; eval-gates en CI.
8. **Observability:** Langfuse (trazas, costo, latencia), alertas.
9. **Security:** OWASP LLM, guardrails, PII masking, IAM, secrets.
10. **Trade-offs:** managed vs self-hosted, costo vs latencia, fine-tune vs RAG.

💡 Di explícitamente los **trade-offs** — eso es lo que distingue a un senior.

---

## 7. Trampas

| Trampa | Antídoto |
|---|---|
| Respuestas largas que se diluyen | Esqueleto + 60–90s + "I can go deeper if useful." |
| "I don't remember [tool]" | "I typically use X for that." |
| Mezclar DevOps/MLOps/LLMOps | Define cada uno en 1 frase. |
| Decir "guardrails" sin saber qué son | Llama Guard / NeMo + validación I/O + OWASP LLM01. |
| Afirmar experiencia que no puedes sostener | Respáldate en **FraudShield** (constrúyelo). |
| Disculparte por el inglés | Habla lento y claro; no te disculpes. |
| No mencionar evaluación | Para LLMs, **siempre** habla de RAGAS/evals — es señal de seniority. |
| Olvidar trade-offs en system design | Cierra cada decisión con su trade-off. |

---

## 8. Ensayo

**7 días antes (1–2 h/día):**
- **Día 1–2:** memoriza §2 (pitch) y §3 (cheatsheet). Grábate diciéndolos en inglés.
- **Día 3:** domina §4 (los 3 gaps) — repite cada guion 5 veces en voz alta.
- **Día 4:** §5 Q1–Q5 en voz alta.
- **Día 5:** §5 Q6–Q10 + §9 (fraude, tu dominio).
- **Día 6:** §6 system design — practica diseñar 2 sistemas en voz alta con cronómetro.
- **Día 7:** simulacro completo: pide a alguien (o a un LLM por voz) que te entreviste 30 min en inglés. Revisa §7 trampas.

**Reglas del ensayo:**
- Siempre **en voz alta y en inglés**.
- **Cronometra** (60–90s).
- Ten **FraudShield abierto** para referenciar componentes reales.
- Cada respuesta debe **nombrar ≥2 herramientas**.

---

> **Recuerda:** la mejor preparación es **terminar FraudShield**. Cuando cada afirmación tuya tenga un componente real detrás, dejarás de "recordar vagamente" y empezarás a "mostrar lo que construiste". Esa es la diferencia entre el screening que tuviste y la entrevista técnica que vas a ganar. 💪
