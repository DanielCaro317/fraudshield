# 🌶️ Diagnóstico y Plan de Aprendizaje — Senior AI Engineer (Proxify)

> **Propósito de este documento:** Diagnosticar la oportunidad de **Proxify (Senior AI Engineer — Generative AI / LLMs)**, analizar los **gaps que quedaron en evidencia en la entrevista**, y definir el **delta de aprendizaje nuevo** respecto al plan de Ceiba/FraudShield. Al final propongo el **mapa de fusión**: cómo inyectar estos temas en los manuales existentes para obtener un **super-proyecto global** que cubra Ceiba + Proxify de una vez.
>
> ⚠️ Este doc vive **fuera** de la carpeta `proxify/` (que contiene intentos previos, caóticos/redundantes). Aquí empezamos limpio.
>
> **Relacionado:** [`PLAN_APRENDIZAJE_CEIBA_ML.md`](./PLAN_APRENDIZAJE_CEIBA_ML.md) · [`manuales/`](./manuales/README.md)

---

## 📑 Índice

1. [Diagnóstico del cargo Proxify](#1-diagnóstico-del-cargo)
2. [Diagnóstico de la entrevista (lo que de verdad pasó)](#2-diagnóstico-entrevista)
3. [Los 3 gaps técnicos críticos + el gap meta (comunicación)](#3-gaps)
4. [Análisis comparativo: Proxify vs Ceiba/FraudShield](#4-comparativo)
5. [El DELTA: temas nuevos que hay que aprender](#5-delta)
6. [Mini-roadmap del delta (semanas extra)](#6-roadmap)
7. [🔗 Mapa de fusión → el Super-Proyecto Global](#7-fusion)
8. [Preparación específica para la entrevista técnica de Proxify](#8-entrevista-tecnica)
9. [Riesgos y reglas de oro](#9-riesgos)

---

## 1. Diagnóstico del cargo

### 1.1 Qué es y en qué se diferencia de Ceiba

| Dimensión | Ceiba (Ingeniero ML) | **Proxify (Senior AI Engineer)** |
|---|---|---|
| Eje principal | Data Engineering + ML híbrido | **GenAI / LLMs puro, en producción** |
| Seniority | 3+ años | **Senior, ownership de arquitectura de IA** |
| Foco técnico | ETL/ELT, dbt, Airflow, SQL, ML clásico | **LLMs, RAG, agentes, prompt eng. + evaluación, IR** |
| Nube | GCP (plus) | **AWS / GCP / Azure** (AWS aparece primero) |
| Modalidad | Híbrido Bogotá | **100% remoto, clientes EU/USA** |
| Lo que evalúan | Amplitud data+IA | **Profundidad en IA de producción + autonomía** |

### 1.2 Lo que Proxify exige (lectura literal del job)

**Responsabilidades núcleo:**
- Diseñar, construir y **desplegar sistemas de IA end-to-end en producción**.
- Ser dueño de features basados en LLM: **RAG**, **agentes de IA y workflows**, **prompt engineering y evaluación**.
- **Arquitectar y optimizar pipelines de IA escalables**.
- Integrar IA en **backends y APIs existentes**.
- Garantizar **performance, confiabilidad y escalabilidad**.

**Requisitos:**
- LLMs (OpenAI, **Anthropic**, open-source), pipelines **RAG** y sistemas de retrieval, **prompt engineering y evaluación**.
- **Python** fuerte. **APIs (FastAPI)**.
- **NLP fundamentals**, **vector databases y embeddings**, **information retrieval**.
- Nube (**AWS/GCP/Azure**). **Autonomía** para decisiones de arquitectura.

**Nice to have (= lo que te hace ganar):**
- **LangChain, LangGraph, LlamaIndex**, **agentes y workflows multi-paso**.
- **Fine-tuning / entrenamiento** de modelos.
- **MLOps (MLflow, Weights & Biases)**, **Docker y Kubernetes**.
- Experiencia en **startups / entornos rápidos**.

> 💡 **Conclusión:** Proxify es **más profundo y más "senior AI" que Ceiba**. Donde Ceiba quiere amplitud (datos+ML), Proxify quiere a alguien que **arquitecte sistemas de IA de producción con LLMs/agentes, los evalúe rigurosamente, los asegure y los escale**, con **autonomía total**. Los "nice to have" (LangGraph, agentes, fine-tuning, W&B, K8s) son exactamente tu zona de oportunidad para destacar.

---

## 2. Diagnóstico entrevista

### 2.1 Contexto real de la llamada
- Fue una **entrevista de screening con RR.HH.** (Mariana, talent acquisition en Brasil), explícitamente **no técnica** ("just a talk to know each other").
- **PERO** al final hizo 4 preguntas técnicas de filtro: **testing, CI/CD, seguridad** y notice/salario. Aunque dijo que no era técnica, **esas respuestas pesan** y deciden si pasas a la **entrevista técnica final**.

### 2.2 Lo que comunicaste sobre tu background (y que ahora hay que SOSTENER con evidencia)
Afirmaste:
- **+7 años en IT**, ~**4 años en IA**.
- Sistema **RAG para detección de fraude en banca** (mencionaste Tech Mahindra, equipo Canadá/India).
- Recuperación **semántica y cuantitativa** sobre la base del banco.
- Modelos **XGBoost, regresión, árboles de decisión**.
- **MLOps end-to-end**: data warehouse → entrenamiento → AWS/GCP → Docker, Kubernetes, FastAPI → MLflow → seguimiento post-despliegue.
- NLP, full-stack (React, Flutter), maestría en IA, estudios en Stanford/España.

> 🎯 **Observación crítica:** Tu narrativa coincide **exactamente** con el proyecto **FraudShield** que ya estamos construyendo (RAG + fraude bancario + retrieval semántico/cuantitativo + MLOps). **FraudShield es la evidencia tangible que respalda lo que dijiste.** Esto es enorme: termina FraudShield y dejas de "afirmar" para "demostrar".

### 2.3 Dónde se notó la falta de preparación (transcripción analizada)

| Pregunta de Mariana | Lo que respondiste | Diagnóstico |
|---|---|---|
| **Testing de APIs y pipelines de IA / frameworks** | "Rajax/Ragas... faithfulness, hallucinations... latency... MLflow... no recuerdo la herramienta de la base vectorial" | ⚠️ Ibas por buen camino (**RAGAS** es correcto) pero **vago, sin estructura, sin nombrar pytest ni el vector DB**. Se notó memoria difusa. |
| **CI/CD pipelines / herramientas** | "algo con LangChain... GitHub Actions... no solo DevOps sino 'envelopes'..." | 🔴 **Respuesta confusa y débil.** "Envelopes"/"MLOps" se mezclaron. No explicaste un pipeline CI/CD real. |
| **Seguridad / privacidad de datos sensibles** | "AWS tiene security walls... prompt engineering... FastAPI security y guardrails... tengo ideas ambiguas sobre eso" | 🔴 **Admitiste ambigüedad.** Conceptos sueltos, sin framework (OWASP LLM, PII, secretos, IAM). |

**Otros patrones a corregir:**
- 🗣️ **Inglés técnico inseguro** ("sorry for my English", muletillas, frases incompletas). No es bloqueante pero resta en una empresa 100% remota anglo.
- 📉 **Respuestas largas y poco estructuradas**, sin método (STAR / problema-solución-resultado).
- 🔧 **No nombraste herramientas con precisión** (el reclutador valora oír "pytest", "Pinecone", "Ragas", "GitHub Actions con eval gates", "Secret Manager").

---

## 3. Gaps

Estos son los temas que **debes dominar sí o sí** antes de la entrevista técnica. Los 3 primeros son los que Mariana tocó; el 4º es transversal.

### 🔴 Gap 1 — Testing y evaluación de sistemas de IA
No es solo "tests de software". En IA hay **3 capas**:
1. **Tests de código/API:** `pytest`, tests de integración, mocking de llamadas a LLM.
2. **Evaluación de LLM/RAG:** **RAGAS** (faithfulness, answer relevancy, context precision/recall), **LLM-as-judge**, datasets dorados (golden sets), detección de alucinaciones.
3. **Performance:** latencia (incluida latencia por token / time-to-first-token), throughput, **pruebas de carga**.

### 🔴 Gap 2 — CI/CD para IA
- **GitHub Actions** a fondo: workflows, jobs, secrets, environments, matrices.
- **CI con "eval gates":** que el pipeline **corra las evals de RAGAS y bloquee el merge** si la calidad cae.
- **CD:** despliegue automático a la nube; **versionado de prompts y modelos**.
- Vocabulario claro: **DevOps vs MLOps vs LLMOps** (no mezclarlos como en la entrevista).

### 🔴 Gap 3 — Seguridad y privacidad en IA
- **OWASP Top 10 para LLM Apps** (marco para hablar con autoridad).
- **Prompt injection** y defensas; **guardrails** (Llama Guard, NeMo Guardrails, validación entrada/salida).
- **PII / datos sensibles:** detección y enmascaramiento (DLP, presidio), minimización.
- **Secretos:** Secret Manager / AWS Secrets Manager; nunca claves en código.
- **Seguridad de API:** auth, rate limiting, **IAM** (GCP y AWS).

### 🟡 Gap 4 (meta) — Comunicación técnica en inglés
- Respuestas **estructuradas** (STAR), **concisas**, **con nombres de herramientas**.
- Un **"guion de tooling"** memorizado por tema (ver §8).
- Práctica de **speaking técnico en inglés**.

---

## 4. Comparativo

### 4.1 Qué YA cubre FraudShield (solapamiento — no repetir)
El plan/manuales de Ceiba ya cubren, y le sirven a Proxify:
- ✅ **Python, FastAPI, Docker** (Manuales 06–07).
- ✅ **RAG básico-intermedio** + embeddings + vector DB (Manual 05).
- ✅ **MLflow, CI/CD con GitHub Actions** (Manual 06).
- ✅ **Seguridad de datos e IA + OWASP LLM + observabilidad** (Manual 08).
- ✅ **Testing código/datos/modelo + performance/Locust** (Manuales 06–07).
- ✅ **Nube (GCP)**, despliegue Cloud Run (Manual 07).
- ✅ **Modelos de fraude (XGBoost, etc.)** (Manual 04).

### 4.2 Qué le FALTA a FraudShield para ser "Senior AI Engineer Proxify"
Aquí está **el delta** (lo nuevo a aprender e inyectar):

| # | Tema nuevo (Proxify lo pide, FraudShield no lo cubre o es superficial) | Prioridad |
|---|---|---|
| D1 | **Agentes de IA y workflows multi-paso (LangGraph)** | 🔴 Alta (nice-to-have estrella) |
| D2 | **Evaluación rigurosa de LLM/RAG (RAGAS, LLM-as-judge, golden sets)** | 🔴 Alta (gap 1) |
| D3 | **Prompt engineering avanzado y versionado/evaluación de prompts** | 🔴 Alta |
| D4 | **Information Retrieval avanzado: hybrid search, re-ranking, métricas IR** | 🔴 Alta |
| D5 | **Observabilidad/tracing de LLM (LangSmith / Langfuse)** | 🟡 Media-Alta |
| D6 | **CI con eval-gates para IA + LLMOps** (profundiza gap 2) | 🔴 Alta |
| D7 | **Seguridad de IA avanzada: guardrails (Llama Guard/NeMo), prompt injection** (gap 3) | 🔴 Alta |
| D8 | **Fine-tuning / PEFT (LoRA/QLoRA)** — ideal en tu RTX 4070 Super | 🟡 Media (nice-to-have) |
| D9 | **Multi-cloud: AWS para IA (Bedrock, SageMaker, Lambda) + Azure panorama** | 🟡 Media |
| D10 | **Weights & Biases (W&B)** para experimentos/evals | 🟡 Media |
| D11 | **Kubernetes (profundidad) + escalabilidad de pipelines de IA** | 🟡 Media |
| D12 | **Comunicación técnica en inglés (STAR + tooling)** | 🔴 Alta (gap 4) |

---

## 5. Delta

Detalle de qué dominar en cada tema nuevo (qué buscar/practicar; tú consigues los recursos).

### D1 · Agentes de IA y workflows (LangGraph) 🌟
- **Fundamentos de agentes:** patrón **ReAct** (reason+act), **tool/function calling**, planning, memoria, bucles.
- **LangGraph:** grafos de estado, nodos/aristas, ciclos, **human-in-the-loop**, checkpoints, persistencia.
- **Patrones:** single-agent con herramientas, **multi-agente** (supervisor/workers), workflows con ramas y reintentos.
- **Caso FraudShield:** un **Agente Investigador de Fraude** que, dado un caso, usa herramientas: (1) consultar la transacción en BigQuery, (2) puntuarla con el modelo, (3) buscar quejas similares vía RAG, (4) redactar un borrador de **reporte de actividad sospechosa (SAR)**. Esto es agentic + multi-step puro.

### D2 · Evaluación de LLM/RAG (gap crítico) 🔴
- **RAGAS:** faithfulness, answer relevancy, context precision, context recall.
- **LLM-as-a-judge:** rúbricas, pairwise, sesgos del juez.
- **Golden datasets / test sets** de preguntas-respuestas; **eval offline vs online**.
- **Detección de alucinaciones**; métricas de groundedness.
- **Eval-driven development:** iterar prompts/retrieval guiado por métricas, no por intuición.

### D3 · Prompt engineering avanzado
- Técnicas: few-shot, **chain-of-thought**, ReAct, **structured output** (JSON/schema), self-consistency.
- **Versionado de prompts** (tratarlos como código), **A/B de prompts**, plantillas.
- Mitigación de fallos: grounding, "responde solo con el contexto", citaciones.

### D4 · Information Retrieval avanzado
- **Hybrid search:** denso (embeddings) + **BM25/keyword**; fusión (RRF).
- **Re-ranking:** cross-encoders, **Cohere Rerank**, MMR.
- **Estrategias de chunking** (fijo, semántico, por estructura) y su impacto.
- **Métricas IR:** precision@k, recall@k, **MRR**, **NDCG**.
- **Vector DBs** (panorama para hablar con propiedad): **pgvector, Pinecone, Weaviate, Qdrant, Chroma, FAISS** — cuándo cada uno.

### D5 · Observabilidad / tracing de LLM
- **LangSmith** o **Langfuse:** trazar cadenas/agentes, ver prompts/respuestas/tokens/latencia/costo, depurar.
- Dashboards de calidad y costo; feedback loop con evals.

### D6 · CI con eval-gates + LLMOps (gap 2 profundizado)
- GitHub Actions: correr **pytest + RAGAS** en cada PR; **fallar si la calidad baja** de un umbral.
- **Versionado de prompts/modelos** en el pipeline; promoción dev→prod.
- Clarificar **DevOps / MLOps / LLMOps** (definiciones y diferencias) para la entrevista.

### D7 · Seguridad de IA avanzada (gap 3 profundizado)
- **OWASP LLM Top 10** memorizado (los 10, con ejemplo de cada uno).
- **Guardrails:** **Llama Guard**, **NeMo Guardrails**, validación de I/O, allow/deny lists.
- **Prompt injection** (directa e indirecta) y defensas; **jailbreaks**.
- **PII:** Microsoft **Presidio** / Cloud DLP para detectar y enmascarar.
- Secretos, IAM (AWS + GCP), rate limiting, límites de costo/abuso.

### D8 · Fine-tuning / PEFT (tu GPU brilla aquí) 🖥️
- **Cuándo** fine-tunear vs RAG vs prompting (matriz de decisión — pregunta típica senior).
- **LoRA / QLoRA**, **PEFT**, cuantización; entrenar un modelo pequeño (ej. clasificar tipo de fraude en quejas) **local en tu RTX 4070 Super**.
- Preparación de datos de fine-tuning; evaluación del modelo afinado.

### D9 · Multi-cloud (AWS foco)
- **AWS para IA:** **Bedrock** (LLMs gestionados), **SageMaker**, **Lambda**, **ECS/EKS**, S3, IAM, Secrets Manager.
- **Equivalencias GCP↔AWS↔Azure** (tabla mental: BigQuery↔Redshift↔Synapse, Cloud Run↔App Runner/Fargate↔Container Apps, Vertex↔SageMaker↔Azure ML, etc.).
- Por qué importa: 70% de clientes Proxify en EU/USA usan AWS.

### D10 · Weights & Biases
- Tracking de experimentos y **W&B** para evals/sweeps; comparar runs; reportes compartibles. Alternativa/complemento a MLflow (el job nombra ambos).

### D11 · Kubernetes + escalabilidad de IA
- K8s: pods, deployments, services, scaling; **cuándo K8s vs serverless** (Cloud Run/Lambda).
- Escalabilidad de pipelines de IA: **async, streaming de tokens, batching, caching de embeddings/respuestas**, colas.

### D12 · Comunicación técnica en inglés
- **Guion de tooling por tema** (memorizado, ver §8).
- Respuestas **STAR** de 60–90s.
- Práctica de speaking; grabarte y revisar.

---

## 6. Roadmap

> Estas son **2–3 semanas adicionales** que se **integran** al plan FraudShield (no son un proyecto aparte). El delta se construye **encima** de FraudShield. Asume que ya vas por las Semanas 5–8 de FraudShield (RAG/MLOps) cuando arrancas el delta.

### 🟪 Semana A — Retrieval avanzado + Evaluación + Observabilidad de IA
**Aprender:** D4 (IR avanzado), D2 (RAGAS/evals), D3 (prompt eng. avanzado), D5 (LangSmith/Langfuse).
**Construir:** Mejorar el RAG de FraudShield → **hybrid search + re-ranking + citas**; añadir **suite de evaluación RAGAS** con golden set; instrumentar con **Langfuse/LangSmith**.
**Entregable:** RAG evaluado con métricas (faithfulness, context recall) + dashboard de trazas.

### 🟪 Semana B — Agentes (LangGraph) + Fine-tuning local
**Aprender:** D1 (agentes/LangGraph), D8 (LoRA/QLoRA en tu GPU).
**Construir:** **Agente Investigador de Fraude** con LangGraph (consulta BD → puntúa → busca quejas → redacta SAR); **fine-tune** un modelo pequeño local para clasificar quejas por tipo de fraude.
**Entregable:** Agente multi-paso funcionando + modelo afinado evaluado.

### 🟪 Semana C — LLMOps senior: CI con eval-gates + Seguridad IA + Multi-cloud
**Aprender:** D6 (CI eval-gates/LLMOps), D7 (guardrails/OWASP/prompt injection), D9 (AWS para IA), D10 (W&B), D11 (K8s/escala), D12 (inglés/STAR).
**Construir:** Pipeline **GitHub Actions** que corre evals y **bloquea si baja la calidad**; **guardrails** anti prompt-injection en el agente; **desplegar una variante en AWS** (Bedrock o ECS) para demostrar multi-cloud.
**Entregable:** CI con eval-gate verde + guardrails probados + demo en AWS + guion de entrevista en inglés ensayado.

---

## 7. Fusion

> 🎯 **El objetivo final que pediste:** no crear manuales nuevos sueltos, sino **fusionar** estos temas en los manuales existentes → un **super-proyecto global** (FraudShield evoluciona a una plataforma de **detección de fraude + IA agentic de producción**) que cubre **Ceiba Y Proxify** a la vez.

### 7.1 Mapa de fusión (tema nuevo → manual destino)

| Tema delta | ¿Cómo se fusiona? | Manual destino |
|---|---|---|
| D4 IR avanzado (hybrid, re-rank, métricas) | Ampliar la sección de retrieval del RAG | **Manual 05** (RAG) |
| D3 Prompt engineering avanzado | Nueva sección de prompting + structured output | **Manual 05** |
| D2 Evaluación RAGAS / LLM-judge / golden set | Nueva sección "Evaluación del RAG" | **Manual 05** (+ usado en CI del 06) |
| D5 Observabilidad LLM (LangSmith/Langfuse) | Añadir a observabilidad | **Manual 05** y **Manual 08** |
| D1 Agentes / LangGraph (Agente de Fraude) | **NUEVO Manual 05B** "Agentes y workflows con LangGraph" | **Manual 05B (nuevo)** |
| D8 Fine-tuning LoRA/QLoRA (local GPU) | **NUEVO Manual** de fine-tuning | **Manual 4B o 5C (nuevo)** |
| D6 CI con eval-gates + LLMOps | Ampliar CI/CD con evals que bloquean merge | **Manual 06** |
| D10 Weights & Biases | Añadir junto a MLflow | **Manual 06** |
| D7 Seguridad IA avanzada (guardrails, OWASP, prompt injection) | Profundizar sección de seguridad de IA | **Manual 08** |
| D9 Multi-cloud (AWS Bedrock/SageMaker) | Añadir "despliegue alternativo en AWS" | **Manual 07** |
| D11 Kubernetes + escalabilidad IA | Añadir sección de escalado (K8s vs serverless, streaming/async) | **Manual 07** |
| D12 Comunicación inglés + entrevista técnica | Ampliar prep de entrevista (Proxify + Ceiba) | **Manual 09** |

### 7.2 Estructura resultante del super-proyecto (manuales tras la fusión)

```
00  Entorno cloud (GCP + AWS básico + local/Ollama)
01  Ingesta y Data Lake
02  ELT con dbt
03  Orquestación Airflow
04  ML de fraude (XGBoost, desbalanceo)
04B 🆕 Fine-tuning local (LoRA/QLoRA en RTX 4070 Super)
05  RAG (ampliado: hybrid search, re-ranking, prompt eng., EVALUACIÓN RAGAS, tracing)
05B 🆕 Agentes y workflows (LangGraph): Agente Investigador de Fraude
06  MLOps + CI/CD + Testing (ampliado: eval-gates, W&B, LLMOps)
07  Despliegue + Performance (ampliado: AWS Bedrock/ECS, Kubernetes, streaming/escala)
08  Seguridad (datos + IA, ampliado: guardrails, OWASP LLM, prompt injection) + Observabilidad (+ Langfuse)
09  Integración + storytelling + entrevista (ampliado: Proxify técnica + inglés/STAR)
```

### 7.3 La narrativa del super-proyecto (una sola historia para ambas empresas)
> **FraudShield** = plataforma cloud de **detección de fraude bancario con IA agentic de producción**: ingiere transacciones y quejas, las transforma (dbt/Airflow), entrena modelos (incl. uno **afinado**), expone un **RAG evaluado con RAGAS** y un **Agente Investigador de Fraude (LangGraph)**, todo **desplegado con CI/CD y eval-gates**, **seguro (guardrails/OWASP)**, **observado (Langfuse/Evidently)** y **escalable (multi-cloud GCP+AWS)**.

- Para **Ceiba** → resaltas: data engineering, dbt/Airflow, ML, GCP, CRISP-DM.
- Para **Proxify** → resaltas: LLMs, RAG evaluado, **agentes/LangGraph**, prompt eng., IR avanzado, LLMOps, seguridad de IA, multi-cloud, fine-tuning.
- **Mismo proyecto, dos pitches.** Y respalda **exactamente** lo que ya dijiste en la entrevista de Proxify.

---

## 8. Entrevista técnica

> El siguiente paso real en Proxify es la **entrevista técnica final**. Prepárate para responder con **estructura + herramientas concretas**. Aquí están las 3 preguntas que fallaste, ahora con guion ganador.

### 8.1 "¿Cómo testeas tus APIs de backend y pipelines de IA?"
**Guion (memoriza la estructura + tools):**
> "En **3 capas**. (1) **Código/API:** `pytest` con tests unitarios e integración, mockeando las llamadas al LLM para determinismo. (2) **Evaluación del LLM/RAG:** uso **RAGAS** para medir *faithfulness*, *answer relevancy* y *context precision/recall* sobre un **golden dataset**, más **LLM-as-judge** para criterios cualitativos. (3) **Performance:** mido **latencia (incluido time-to-first-token)** y throughput con **Locust/k6**. Y todo esto corre en **CI** como *eval-gate*: si la calidad baja de un umbral, el pipeline falla."

### 8.2 "¿Has montado pipelines CI/CD? ¿Con qué herramientas?"
**Guion:**
> "Sí, con **GitHub Actions**. En cada PR corro **lint (ruff/black) → tests (pytest) → evals (RAGAS) → build de imagen Docker → push a Artifact Registry**. En `main`, **CD automático** a **Cloud Run** (o ECS en AWS). Versiono **prompts y modelos**, y promociono dev→prod con aprobación. Distingo **DevOps** (infra/app), **MLOps** (ciclo de vida del modelo) y **LLMOps** (prompts, evals, guardrails)."

### 8.3 "¿Qué prácticas de seguridad/privacidad aplicas con datos sensibles?"
**Guion:**
> "Me guío por el **OWASP Top 10 para LLMs**. Concretamente: **secretos en Secret Manager** (nunca en código), **IAM con mínimo privilegio**, **detección y enmascaramiento de PII** con **Cloud DLP / Presidio**, **guardrails** (Llama Guard / NeMo) y validación de I/O contra **prompt injection**, **rate limiting** y límites de costo en la API, y cifrado en tránsito/reposo. En el RAG, el modelo **solo responde con el contexto recuperado y cita la fuente**, para evitar fugas y alucinaciones."

### 8.4 Otras preguntas senior probables (prepara guion)
- "RAG vs fine-tuning vs prompting: ¿cuándo cada uno?"
- "¿Cómo diseñas un **agente** con LangGraph? ¿Cómo manejas errores/loops?"
- "¿Cómo evalúas si tu RAG **alucina**?"
- "¿Cómo **escalas** un sistema LLM en producción? (caching, streaming, async)."
- "¿Hybrid search y re-ranking — por qué mejoran el retrieval?"
- "Cuéntame un sistema de IA end-to-end que hayas construido." → **FraudShield**.

### 8.5 Comunicación (gap meta)
- Respuestas **STAR**, 60–90s, **nombrando herramientas**.
- Ten un **"cheat sheet" de tooling por tema** y practícalo en **inglés** en voz alta.
- Evita "I don't remember" → mejor "I typically use X for that".

---

## 9. Riesgos

- ⚠️ **No inflar más de lo que puedas sostener.** Termina FraudShield para que tu narrativa de fraude+RAG+MLOps sea **real y demostrable**.
- ⚠️ **El delta es profundo, no ancho:** Proxify premia **profundidad en IA de producción**. Prioriza D1, D2, D6, D7 (lo que te preguntaron + agentes).
- ⚠️ **Inglés:** dedica tiempo a speaking técnico; en 100% remoto anglo, importa.
- ⚠️ **Multi-cloud sin perderte:** GCP es tu base; aprende AWS por **equivalencias**, no desde cero.

**Reglas de oro**
1. **Un solo super-proyecto (FraudShield), dos pitches** (Ceiba y Proxify).
2. **Cada afirmación de la entrevista = un entregable en el repo.**
3. **Evals y guardrails NO son opcionales** para un Senior AI Engineer.
4. **Nombra herramientas con precisión.** La vaguedad fue tu mayor enemigo.
5. **Desarrolla local (GPU), evalúa, despliega en nube.**

---

## ✅ Resumen ejecutivo

Proxify busca un **Senior AI Engineer de GenAI/LLMs para producción**, más profundo en IA que Ceiba. En la entrevista (de RR.HH., pero con filtro técnico) quedaron en evidencia 3 gaps —**testing/evaluación de IA, CI/CD y seguridad**— más una vaguedad general y nervios de inglés. La buena noticia: **tu narrativa coincide con FraudShield**, así que no construimos otro proyecto: **lo potenciamos**. El **delta** a aprender (agentes/LangGraph, evaluación RAGAS, IR avanzado, observabilidad LLM, CI con eval-gates, seguridad de IA avanzada, fine-tuning local, multi-cloud/AWS, W&B, K8s, e inglés/STAR) se **fusiona** en los manuales existentes vía el mapa de §7, produciendo un **super-proyecto global** que satisface **ambas** vacantes con una sola historia demostrable — y te prepara para responder con autoridad la entrevista técnica final.

---

> **➡️ Siguiente paso (tras tu aprobación):** ejecutar la **fusión** del §7 en los manuales (ampliar 05, 06, 07, 08, 09 y crear 04B fine-tuning y 05B agentes). No antes de que valides este diagnóstico y plan.
