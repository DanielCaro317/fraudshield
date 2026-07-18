# 🎯 Plan de Aprendizaje Intensivo — Ingeniero Machine Learning (Ceiba Software)

> **Proyecto guía:** **FraudShield** — plataforma cloud de detección de fraude bancario + consultas semánticas/cualitativas (RAG), construida en GCP. Complementa experiencia real en modelos de detección de fraude (tipo Scotiabank).
>
> **Objetivo:** Cubrir, en 9 semanas, TODO lo que exige el cargo (Data Engineering + IA/ML) **a nivel senior**, construir un portafolio demostrable y llegar listo a la entrevista de Ceiba — incluyendo los "plus" (GCP) y prácticas senior (CI/CD, DevOps, seguridad, testing, observabilidad).
>
> **Perfil de partida:** Intermedio sólido (Python y SQL funcionales, ML básico).
> **Ritmo:** Intensivo, ~20–25 h/semana (≈180–225 h totales).
> **Modalidad de recursos:** Sin cursos pagos. Este plan dice **qué dominar** y **qué construir**; tú eliges los recursos.
> **Hardware:** GCP (nube, lo principal) + tu PC local (RTX 4070 Super, Ryzen 7900, 64 GB RAM) como complemento para LLMs locales y procesamiento pesado.

---

## 📑 Índice

1. [Diagnóstico: qué pide el cargo vs. dónde estás](#1-diagnóstico)
2. [Mapa de requisitos → herramientas ideales](#2-mapa-de-requisitos--herramientas)
3. [El Stack que vas a aprender (y por qué)](#3-stack-tecnológico)
4. [Estrategia: el Proyecto Capstone (FraudShield)](#4-estrategia-capstone)
5. [Cronograma semana a semana (9 semanas)](#5-cronograma)
6. [Bloque Senior: temas transversales que te suben de nivel](#6-bloque-senior)
7. [Estrategia híbrida: nube + tu PC local](#7-hibrido)
8. [Criterios de dominio (checklist por tema)](#8-criterios-de-dominio)
9. [Preparación específica para la entrevista de Ceiba](#9-entrevista)
10. [Riesgos, atajos y reglas de oro](#10-riesgos)

---

## 1. Diagnóstico

### 1.1 Lo que el cargo realmente busca

Aunque se llama "Ingeniero Machine Learning", el texto revela un **perfil híbrido Data Engineer + ML/AI Engineer**. Lo separo en 6 bloques de competencia (los 5 del cargo + el bloque senior que tú añadiste):

| Bloque | Peso | Tu estado inicial |
|---|---|---|
| **A. Data Engineering** (ETL/ELT, SQL relacional+NoSQL, Airflow, dbt, calidad de datos) | 🔴 Alto | ⚠️ Hueco grande |
| **B. ML / Estadística** (modelado tradicional y avanzado, EDA, detección de fraude) | 🟡 Medio-Alto | 🟢 Base existente |
| **C. IA Generativa** (LLMs, RAG, consultas semánticas) | 🔴 Alto | 🔴 Hueco total |
| **D. MLOps + Nube** (despliegue, GCP) | 🔴 Alto | 🔴 Hueco grande |
| **E. Transversales** (CRISP-DM, Ágil, comunicación a stakeholders) | 🟡 Medio | ⚠️ Por formalizar |
| **F. Senior/Producción** (CI/CD, DevOps, seguridad de datos e IA, testing, performance, observabilidad) | 🔴 Alto (diferenciador) | 🔴 Por construir |

> **Lectura estratégica:** Tu base de Python/SQL/ML te ahorra ~3 semanas. El grueso del tiempo va a **Data Engineering (A)**, **RAG/LLMs (C)**, **MLOps/GCP (D)** y el **Bloque Senior (F)**. Ahí está tu ventaja: poca gente combina detección de fraude + RAG + MLOps + seguridad/observabilidad en un mismo perfil.

### 1.2 Análisis literal de cada requisito

| # | Requisito del job.md | Traducción a lo que debes saber hacer |
|---|---|---|
| 1 | 3 años exp. ML/Data Engineer | Se **compensa con portafolio sólido** (FraudShield) que demuestre el nivel. |
| 2 | EDA, prospección de fuentes (estructuradas y no estructuradas), calidad de datos | EDA con pandas/SQL, profiling, nulos/duplicados/outliers; transacciones (estructurado) + quejas (texto). |
| 3 | Modelamiento estadístico y ML tradicional y avanzado | Regresión/clasificación, ensembles (XGBoost/LightGBM), **clases desbalanceadas** (núcleo del fraude), validación, métricas. |
| 4 | **Apps con LLMs y arquitectura RAG** | RAG completo: embeddings → vector DB → retrieval → LLM, para consultas semánticas/cualitativas. |
| 5 | Python | Subir a nivel "ingeniería" (estructura, tipado, tests). |
| 6 | MLOps: despliegue de soluciones | Empaquetar (Docker), servir (FastAPI), versionar (MLflow/Vertex), CI/CD. |
| 7 | SQL relacional **y NO relacional** | BigQuery/Cloud SQL + Firestore/MongoDB; consultas avanzadas. |
| 8 | Diseñar y automatizar **ETL/ELT** | Pipelines E/T/L; entender ETL vs ELT. |
| 9 | **Airflow, dbt** | Orquestar (Airflow/Composer) y transformar (dbt). |
| 10 | Comunicación a stakeholders no técnicos | Contar la historia del fraude detectado; dashboards y narrativa. |
| 11 | **CRISP-DM / Ágil** | Citar y aplicar las 6 fases de CRISP-DM y ceremonias Scrum/Kanban. |
| 12 | Educación técnica afín | Ya cumples. |
| ➕ | **Plus: GCP** | BigQuery, Cloud Storage, Vertex AI, Cloud Run, Composer. |
| ➕ | Plus: React | Dashboard antifraude. |
| ➕ | **Plus: metadatos financieros** | Datos transaccionales bancarios, tipos de transacción, señales de fraude. |
| 🆕 | **Senior (tú lo añadiste):** CI/CD, DevOps, seguridad datos+IA, testing, performance, observabilidad | Lo que separa a un junior de un senior listo para producción. |

---

## 2. Mapa de requisitos → herramientas

> Regla: **una herramienta por necesidad**, la estándar de la industria, priorizando GCP.

| Necesidad | Herramienta principal | Por qué / alternativa |
|---|---|---|
| Lenguaje | **Python 3.11+** | Estándar del cargo. |
| Entorno | **Cloud Shell** (nube) + **VS Code** (local) + **Git/GitHub** | Reproducibilidad. |
| SQL relacional | **BigQuery** + **Cloud SQL (PostgreSQL)** | DW + base transaccional/pgvector. |
| NoSQL | **Firestore** (o MongoDB Atlas) | Cubre "no relacional". |
| Análisis | **pandas**, **NumPy**, **ydata-profiling** | EDA y calidad. |
| Visualización | **matplotlib/seaborn**, **Looker Studio** | Gráficas y dashboards GCP. |
| ML tradicional | **scikit-learn**, **statsmodels** | Estadística + ML clásico. |
| ML avanzado | **XGBoost / LightGBM**, **imbalanced-learn** | Ensembles + clases desbalanceadas (fraude). |
| ETL/ELT | **dbt-core** + **Python** | dbt explícito en el job. |
| Orquestación | **Apache Airflow** (Cloud Composer) | Explícito en el job. |
| LLMs / RAG | **LangChain/LlamaIndex** + **Vertex AI** y/o **Claude (Anthropic)** + **Ollama local** | RAG explícito; Ollama local ahorra costos. |
| Vector DB | **pgvector** (Cloud SQL) o **Vertex AI Vector Search** | Embeddings y retrieval. |
| Tracking modelos | **MLflow** / **Vertex AI Model Registry** | Estándar MLOps. |
| Serving / API | **FastAPI** + **Docker** | Despliegue. |
| Contenedores | **Docker** + **Artifact Registry** | Imágenes. |
| **CI/CD** | **GitHub Actions** (+ Cloud Build) | Automatización build/test/deploy. |
| **IaC / DevOps** | **Terraform** | Infraestructura como código (senior). |
| Nube | **Google Cloud Platform** | BigQuery, GCS, Vertex AI, Cloud Run, Composer. |
| Frontend (plus) | **React** (Vite) | Dashboard antifraude. |
| **Testing** | **pytest**, **dbt tests**, **Great Expectations**, **deepchecks/giskard** | Código, datos y modelos. |
| **Performance/Carga** | **Locust** / **k6** | Pruebas de carga de la API. |
| **Observabilidad** | **Cloud Logging/Monitoring**, **Evidently AI** | Logs, métricas, **drift** de datos/modelo. |
| **Seguridad** | **Secret Manager**, **IAM**, **DLP API**, **OWASP LLM Top 10** | Datos sensibles + seguridad de IA. |
| Metodología | **CRISP-DM** + **Scrum/Kanban** | Marco del job. |

---

## 3. Stack tecnológico

Arquitectura mental de FraudShield (esto es lo que construyes):

```
   FUENTES                      GCP (todo en la nube)                         SENIOR (transversal)
   ├─ PaySim (transacciones)─┐                                                ┌───────────────────┐
   │   ~6.3M filas           │   Cloud Storage      BigQuery (DW)             │ CI/CD (GH Actions)│
   ├─ CFPB (quejas/texto) ───┼──► (Data Lake) ───►  fraud_raw / marts         │ Terraform (IaC)   │
   └─ (APIs banco futuras)   │        ▲                  │                     │ pytest/dbt tests  │
                             │   AIRFLOW (Composer) ──► dbt (ELT, features)    │ Seguridad (IAM,   │
                             │        │                  │                     │  Secret Mgr, DLP, │
                             │        │       ┌──────────┴─────────┐           │  OWASP LLM Top10) │
                             │        │       ▼                    ▼           │ Observabilidad    │
                             │   ML fraude (BQ ML/Vertex)   RAG consultas      │  (Logging, drift  │
                             │        │                     semánticas         │  con Evidently)   │
                             │        ▼                     (pgvector+LLM)      │ Load test (Locust)│
                             │   MLflow/Vertex Registry          │             └───────────────────┘
                             │        │                          │
                             │        ▼                          ▼
                             │   FastAPI + Docker ──► Cloud Run (API scoring + chat)
                             │                          │
                             └──────────────────────────┼──────────────────────────►
                                                        ▼
                                       React Dashboard (equipo antifraude)
```

Si construyes **una sola cosa con todo este flujo y sus prácticas senior**, cubres ~100% del job y te posicionas por encima del promedio. Eso es el Capstone.

---

## 4. Estrategia Capstone

### 4.1 La idea central

En lugar de estudiar temas sueltos, construyes **UN proyecto integral de detección de fraude bancario** que crece semana a semana hasta cubrir todos los requisitos. Aprendes cada herramienta **usándola**, no en abstracto.

> **Proyecto: "FraudShield"** — Plataforma de detección de fraude para el departamento antifraude de un banco.
>
> Ingiere millones de transacciones + narrativas de quejas de clientes, las transforma en features de fraude dentro de un Data Warehouse, entrena un modelo de detección de fraude (clases desbalanceadas), lo despliega como API que puntúa transacciones en tiempo real, y ofrece un asistente de **consultas semánticas y cualitativas (RAG)** para que los analistas pregunten en lenguaje natural sobre patrones, casos y quejas. Todo orquestado, seguro, testeado, monitoreado y en la nube.

### 4.2 Por qué este proyecto es ideal para Ceiba (y para tu historia)

- ✅ **Complementa tu experiencia en Scotiabank** (detección de fraude) → narrativa potente en entrevista.
- ✅ Datos **estructurados** (transacciones) y **no estructurados** (quejas/narrativas) → requisito #2.
- ✅ **Calidad de datos** (saldos inconsistentes, nulos, fugas temporales) → requisito #2.
- ✅ **ML estadístico y avanzado** con el reto real de **clases desbalanceadas** → requisito #3.
- ✅ **RAG para consultas semánticas/cualitativas** → requisito #4 (el más diferenciador).
- ✅ **ETL/ELT + dbt + Airflow** → requisitos #8, #9.
- ✅ **SQL relacional (BigQuery/Cloud SQL) + NoSQL (Firestore)** → requisito #7.
- ✅ **MLOps + despliegue + GCP** → requisito #6 y plus.
- ✅ **Datos transaccionales financieros** → plus de "metadatos financieros".
- ✅ **React dashboard** → plus.
- ✅ **CI/CD, seguridad, testing, observabilidad** → te muestra como **senior listo para producción**.
- ✅ Lo gestionas con **CRISP-DM** + tablero **Kanban** → requisito #11.

### 4.3 Fuentes de datos (gratuitas, gran volumen)

- **Transacciones (estructurado, ~6.3M filas):** PaySim — *"Synthetic Financial Datasets For Fraud Detection"* (Kaggle, `ealaxi/paysim1`). Tipos de transacción, montos, saldos y etiqueta `isFraud`.
- **Quejas (no estructurado, texto):** *Consumer Complaint Database* (CFPB) — narrativas reales de fraude/estafas/cargos no autorizados. Base de las consultas semánticas (RAG).
- **(Opcional) Tarjetas de crédito:** *Credit Card Fraud Detection* (Kaggle, ULB) — features anonimizadas, útil para reforzar el modelado.

---

## 5. Cronograma

> **Formato por semana:** objetivo → temas → qué construir → entregable verificable.
> **Regla de oro:** cada semana termina con algo **subido a GitHub** y un párrafo de README. Lo que no está en GitHub, no existe para el reclutador.
> 📘 Cada semana tiene (o tendrá) su **manual paso a paso** en la carpeta `manuales/`.

---

### 🟦 SEMANA 0 (Días 1–2) — Cimientos y entorno · _Manual 00_
**Objetivo:** Entorno cloud listo y repo `fraudshield` creado.
- GCP (free tier, billing, presupuesto/alertas), **Cloud Shell**, `gcloud`, APIs habilitadas.
- GitHub + repo con estructura profesional; Git esencial.
- (Local) Instalar VS Code, Docker Desktop, Ollama (para LLM local más adelante).
**Entregable:** Repo `fraudshield` con estructura, README y primer commit.

---

### 🟦 SEMANA 1 — Data Engineering: ingesta, Data Lake y SQL de fraude · _Manual 01_
**Objetivo:** Dominar SQL avanzado y construir la capa de ingesta.
- SQL avanzado: JOINs, CTEs, **window functions** (LAG, ROW_NUMBER, OVER/PARTITION), agregaciones.
- ETL vs ELT; Data Lake por capas (raw/staging/curated); NoSQL (cuándo usarlo).
- Ingesta de PaySim + CFPB → Cloud Storage → BigQuery.
**Qué construir:** Scripts de ingesta + 10 consultas SQL de fraude (tasa de fraude por tipo, features de velocidad, inconsistencia de saldos).
**Entregable:** `extract/` con scripts + `queries.sql`; datos en BigQuery (~6.3M filas).

---

### 🟦 SEMANA 2 — ELT moderno: dbt + Data Warehouse · _Manual 02_
**Objetivo:** Aprender **dbt** y modelar features de fraude en **BigQuery**.
- GCP: BigQuery a fondo, costos, particionado/clustering.
- dbt-core: modelos, `ref()`, materializaciones, `sources`, **tests** (unique/not_null/relationships), docs/lineage.
- Arquitectura por capas (staging → intermediate → marts / bronze-silver-gold).
- **Calidad de datos declarativa** (tests dbt + Great Expectations conceptual).
**Qué construir:** Proyecto dbt: `stg_transactions` → `int_account_features` (velocidad, saldos, agregados por cuenta) → `mart_fraud_features` (tabla de features lista para ML).
**Entregable:** `dbt_project/` con tests verdes y `dbt docs` (lineage).

---

### 🟦 SEMANA 3 — Orquestación con Airflow + Calidad · _Manual 03_
**Objetivo:** Automatizar el pipeline con **Airflow (Cloud Composer)** y formalizar EDA/calidad.
- Airflow: DAGs, operadores, dependencias, scheduling, idempotencia, XComs, sensores.
- Composer (Airflow gestionado) vs Airflow local en Docker.
- EDA profundo + calidad: `ydata-profiling`, nulos/duplicados/outliers, **fuga de datos (data leakage)** en fraude.
**Qué construir:** DAG: `ingesta → BigQuery → dbt run → dbt test → validación`. Notebook de EDA con hallazgos de calidad.
**Entregable:** `dags/fraud_pipeline.py` corriendo + `notebooks/01_eda.ipynb`.

---

### 🟦 SEMANA 4 — ML: detección de fraude (tradicional y avanzado) · _Manual 04_
**Objetivo:** Modelo de fraude robusto bajo **CRISP-DM**.
- CRISP-DM formal (6 fases) aplicado al caso.
- Estadística: regresión logística (statsmodels, interpretación), supuestos.
- ML clásico (scikit-learn): pipelines, validación cruzada, **métricas para desbalanceo** (precision, recall, F1, **AUC-PR**, matriz de confusión, costo de FN vs FP).
- **Clases desbalanceadas:** undersampling/oversampling (SMOTE, `imbalanced-learn`), `scale_pos_weight`.
- ML avanzado: **XGBoost/LightGBM**, tuning (Optuna), **SHAP** (explicabilidad para el área de riesgo).
- Feature engineering de fraude (velocidad, montos atípicos, comportamiento de cuenta).
**Qué construir:** Modelo de fraude: baseline (logística) vs XGBoost; manejo de desbalanceo; explicación SHAP.
**Entregable:** `notebooks/02_modeling.ipynb` + `ml/train.py` reproducible, documentado por fases CRISP-DM.

---

### 🟦 SEMANA 5 — IA Generativa: RAG para consultas semánticas/cualitativas · _Manual 05_
**Objetivo:** Construir el asistente **RAG** sobre narrativas de quejas/casos de fraude (el diferenciador).
- Fundamentos LLM: tokens, contexto, prompting, system prompts, alucinaciones.
- **Embeddings** y búsqueda semántica; **vector DB** (pgvector en Cloud SQL / Vertex Vector Search).
- **Arquitectura RAG**: carga → chunking → embeddings → indexación → retrieval (top-k) → augmentation → generación.
- Framework: LangChain o LlamaIndex; LLM vía **Vertex AI / Claude** (nube) y/o **Ollama local** (gratis, tu RTX 4070 Super).
- Calidad RAG: estrategias de chunking, re-ranking, **citas a la fuente**, evaluación (relevancia/fidelidad).
**Qué construir:** Asistente "Pregúntale a los casos": indexas las narrativas de quejas; el analista pregunta ("¿qué patrones de estafa por transferencia reportan los clientes?") y responde **con citas**.
**Entregable:** `rag/` con pipeline de ingesta de documentos + CLI/endpoint que responde con fuentes.

---

### 🟦 SEMANA 6 — MLOps + CI/CD + DevOps + Testing · _Manual 06_
**Objetivo:** Llevar modelo y RAG de "notebook" a "producto" con prácticas senior.
- **MLflow / Vertex Model Registry:** tracking de experimentos, versionado de modelos.
- **FastAPI:** endpoints REST (`/score`, `/ask`), validación Pydantic, Swagger.
- **Docker** + **Artifact Registry**; buenas prácticas (multi-stage, slim, usuario no-root).
- **Testing (senior):**
  - Código: **pytest** (unitarias + integración), cobertura, `ruff`/`black` (lint/format).
  - Datos: **dbt tests** + **Great Expectations** (validación de esquemas/rangos).
  - Modelo: tests de comportamiento (**deepchecks/giskard**), umbrales mínimos de métricas.
- **CI/CD con GitHub Actions:** pipeline lint → test → build imagen → push a Artifact Registry.
- **DevOps/IaC:** introducción a **Terraform** (declarar bucket, dataset, Cloud Run).
**Qué construir:** API dockerizada con `/score` y `/ask`; suite de tests; workflow CI en verde; modelo registrado en MLflow.
**Entregable:** `api/` + `.github/workflows/ci.yml` + tests + `infra/` (Terraform inicial).

---

### 🟦 SEMANA 7 — Despliegue en GCP + Dashboard + Performance · _Manual 07_
**Objetivo:** Solución viva en internet, con cara para stakeholders y probada bajo carga.
- **Cloud Run:** desplegar el contenedor (de imagen Docker a URL pública); CD automático desde GitHub Actions.
- **Cloud Composer / Dataform**: panorama de Airflow/dbt gestionados.
- **Vertex AI** (panorama): entrenamiento, endpoints, registry, RAG Engine.
- **React (Vite):** componentes, hooks, `fetch` a la API; tabla de transacciones marcadas + chat RAG.
- **Performance/Pruebas de carga:** **Locust/k6** contra la API; latencia p95, throughput, autoscaling de Cloud Run.
**Qué construir:** API en Cloud Run (URL pública) + dashboard React que consume `/score` y `/ask` + reporte de prueba de carga.
**Entregable:** URL pública + `frontend/` + `tests/load/` con resultados.

---

### 🟦 SEMANA 8 — Seguridad (datos + IA) y Observabilidad · _Manual 08_
**Objetivo:** Blindar y monitorear la solución como un senior (lo que tú pediste añadir).
- **Seguridad de datos:** IAM (mínimo privilegio), **Secret Manager** (claves/API keys fuera del código), cifrado, **DLP API** para detectar/enmascarar PII en quejas, datos sintéticos/anonimización.
- **Seguridad de IA (LLM):** **OWASP LLM Top 10** — **prompt injection**, fuga de datos por el LLM, jailbreaks, guardrails, validación de entradas/salidas, límites de costo/abuso; seguridad de modelos ML (data poisoning, model theft).
- **Observabilidad / post-despliegue:**
  - **Cloud Logging & Monitoring:** logs estructurados, métricas, **alertas**, dashboards, error reporting.
  - **Debugging en producción:** trazas, reproducción de errores, rollback.
  - **Monitoreo de ML:** **data drift / concept drift** con **Evidently AI**; reentrenamiento; alertas de caída de métricas.
**Qué construir:** Secrets en Secret Manager, escaneo DLP sobre las quejas, guardrails anti prompt-injection en el RAG, dashboard de monitoreo + alerta de drift.
**Entregable:** `docs/security.md` (modelo de amenazas + controles) + monitoreo activo + guardrails en el RAG.

---

### 🟦 SEMANA 9 — Integración, comunicación y entrevista · _Manual 09_
**Objetivo:** Pulir el portafolio, ensayar narrativa y blindar la entrevista.
- **Storytelling de datos:** historia para stakeholders (problema de fraude → datos → solución → impacto: $ ahorrados, FN evitados).
- **Ágil/Scrum/Kanban** y **CRISP-DM** mapeados a tu proyecto.
- README maestro con diagrama de arquitectura, GIFs, instrucciones; limpieza del repo.
- **Glosario de fraude/banca:** tipos de transacción, señales de fraude, falsos positivos/negativos y su costo, KYC/AML básico, **metadatos financieros**.
- Deck/Loom de 5 min; actualizar CV y LinkedIn.
**Entregable:** Portafolio pulido + simulacro de entrevista respondido por escrito.

---

## 6. Bloque Senior

> Esto es lo que pediste añadir y lo que te separa de un perfil junior. Se integra en las Semanas 6–8, pero aquí está el panorama consolidado para que lo veas como sistema.

### 6.1 CI/CD y DevOps
- **CI (Integración Continua):** en cada push, GitHub Actions corre lint + tests + build de imagen. Nada se mergea roto.
- **CD (Despliegue Continuo):** al pasar CI en `main`, se despliega automáticamente a Cloud Run.
- **IaC (Infraestructura como Código):** **Terraform** declara tus recursos GCP (buckets, datasets, Cloud Run) → reproducible, versionado, sin "clics manuales".
- **GitOps:** la rama `main` es la fuente de verdad de lo que está en producción.

### 6.2 Testing (3 niveles)
- **Código:** `pytest` (unitarias + integración), `ruff`/`black`, cobertura mínima.
- **Datos:** `dbt tests` + **Great Expectations** (esquemas, rangos, unicidad, frescura).
- **Modelo:** **deepchecks/giskard** (sesgo, fugas, robustez), umbrales mínimos de métricas en CI (si AUC-PR cae, falla el pipeline).

### 6.3 Performance y pruebas de carga
- **Locust / k6:** simulan miles de peticiones a `/score`. Mides latencia p50/p95, throughput, errores.
- **Optimización:** caching, batching, autoscaling de Cloud Run, índices en BigQuery (particionado/clustering).

### 6.4 Seguridad de datos
- **IAM** con mínimo privilegio; **service accounts** dedicadas.
- **Secret Manager:** claves y API keys NUNCA en el código/Git.
- **DLP API:** detectar y enmascarar **PII** (nombres, cuentas) en las quejas.
- **Anonimización / datos sintéticos** (PaySim ya es sintético — punto a favor en banca).
- Cifrado en reposo y en tránsito (por defecto en GCP).

### 6.5 Seguridad de IA (crítico y muy senior)
- **OWASP Top 10 para LLM Apps:** prompt injection, fuga de datos sensibles vía el LLM, output handling inseguro, consumo excesivo (costos), envenenamiento de datos.
- **Guardrails:** validación de entradas/salidas, listas de bloqueo, límites de tokens/costo, "no responder fuera de contexto", citar solo fuentes recuperadas.
- **Seguridad de modelos ML:** data poisoning, model inversion/extraction, adversarial inputs.

### 6.6 Observabilidad y debugging post-despliegue
- **Logging estructurado** + **Cloud Monitoring** (métricas, dashboards, **alertas**).
- **Error Reporting / tracing** para depurar incidentes en producción; estrategia de **rollback**.
- **Monitoreo de ML:** **data drift** y **concept drift** con **Evidently AI**; disparadores de **reentrenamiento**; alertas si las métricas caen.

### 6.7 Otros temas senior que te hacen destacar
- **Gobernanza de datos / linaje** (dbt docs, catálogo).
- **Optimización de costos en la nube** (FinOps: presupuestos, apagar Composer, BigQuery slots).
- **Documentación de decisiones** (ADRs — Architecture Decision Records en `docs/`).
- **Versionado de datos/modelos** (DVC conceptual / Vertex datasets).

---

## 7. Híbrido

Tu PC (RTX 4070 Super · Ryzen 7900 · 64 GB RAM) **no reemplaza** la nube (el portafolio debe ser cloud para impresionar a Ceiba), pero la **complementa** inteligentemente:

| Tarea | Dónde | Por qué |
|---|---|---|
| Portafolio, despliegue, orquestación, DW | **GCP (nube)** | Es lo que el cargo valora y lo que se ve "profesional". |
| **LLM y embeddings para desarrollar el RAG** | **Local (Ollama + GPU)** | Gratis e ilimitado mientras experimentas; evitas gastar API/créditos. |
| **Preparación pesada de datos** (consolidar PaySim, filtrar CFPB) | **Local (64 GB RAM)** | Cloud Shell solo tiene 5 GB; tu RAM lo hace en minutos. |
| Entrenar/tunear XGBoost rápido | **Local (CPU/GPU)** | Iteración veloz; luego registras el modelo final en la nube. |
| Probar Docker/Airflow antes de pagar Composer | **Local (Docker Desktop)** | Practicas sin costo; despliegas en nube cuando esté listo. |

> 💡 **Regla:** *desarrolla y experimenta local (gratis), entrega y despliega en la nube (impresionante).* Esto además es un argumento senior en entrevista: sabes optimizar costos.

---

## 8. Criterios de dominio

> Marca cada ítem solo cuando puedas **hacerlo sin tutorial al lado**.

**SQL y bases de datos**
- [ ] Window functions y CTEs sin consultar sintaxis.
- [ ] Relacional vs NoSQL: cuándo cada uno.

**Data Engineering (ETL/ELT, dbt, Airflow)**
- [ ] Explico ETL vs ELT y justifico ELT.
- [ ] Modelo dbt con `ref`, tests y materialización adecuada.
- [ ] DAG de Airflow idempotente con dependencias y schedule.
- [ ] Detecto y documento problemas de calidad (incl. data leakage).

**ML / Detección de fraude**
- [ ] Aplico las 6 fases de CRISP-DM.
- [ ] Manejo **clases desbalanceadas** y justifico **AUC-PR/recall** sobre accuracy.
- [ ] Explico el costo de un falso negativo vs falso positivo en fraude.
- [ ] Explico un modelo con SHAP a alguien no técnico.

**IA Generativa / RAG**
- [ ] Dibujo la arquitectura RAG de memoria.
- [ ] Explico chunking, embeddings, retrieval y por qué reducen alucinaciones.
- [ ] Mi RAG cita fuentes.

**MLOps / Nube / Senior**
- [ ] Empaqueto modelo en Docker + FastAPI y lo corro.
- [ ] Registro experimentos en MLflow.
- [ ] Despliego en Cloud Run con CI/CD (GitHub Actions).
- [ ] Tengo tests de código, datos y modelo.
- [ ] Hago una prueba de carga e interpreto p95.
- [ ] Explico controles de seguridad de datos (IAM, Secret Manager, DLP).
- [ ] Explico **OWASP LLM Top 10** y mis guardrails.
- [ ] Detecto **data drift** y sé cuándo reentrenar.

**Transversales**
- [ ] Cuento mi proyecto en 5 min a un perfil no técnico.
- [ ] Manejo vocabulario Scrum/Kanban.

---

## 9. Entrevista

### 9.1 Preguntas probables
- "Explícame una arquitectura RAG que hayas construido."
- "¿ETL vs ELT? ¿Cuándo cada uno?"
- "¿Cómo orquestas un pipeline? ¿Qué es un DAG?"
- "¿Cómo aseguras la calidad de los datos?"
- "¿Cómo manejas clases desbalanceadas en fraude? ¿Qué métrica usas y por qué?"
- "¿Cómo despliegas un modelo en producción? ¿CI/CD?"
- "¿Cómo monitoreas un modelo en producción? ¿Qué es drift?"
- "¿Cómo proteges datos sensibles y una app con LLM?"
- "Cuéntame un proyecto end-to-end." → **Aquí brilla FraudShield.**
- "¿Cómo explicarías un hallazgo a un gerente no técnico?"
- "¿Conoces CRISP-DM? ¿Cómo lo aplicas?"

### 9.2 Tu arma secreta
Casi cualquier pregunta se responde con: *"En FraudShield hice exactamente eso..."*. Un proyecto real end-to-end + tu experiencia previa en fraude (Scotiabank) es una combinación muy fuerte. Prepara la narrativa en 2 niveles: técnico (para el ingeniero) y de negocio (para el manager).

### 9.3 Cómo posicionar la falta de "3 años"
No mientas. Posiciónate: *"Construí una plataforma de detección de fraude end-to-end en GCP: ingesta, ELT con dbt y Airflow, modelo con clases desbalanceadas, RAG para consultas semánticas, desplegada con CI/CD, segura y monitoreada. Complementa mi experiencia previa en modelos de fraude. Aquí está el repo funcionando."* La evidencia tangible neutraliza el filtro de años.

---

## 10. Riesgos

**Riesgos y mitigación**
- ⚠️ **Dispersión:** no abras 10 tutoriales; aprende lo justo para avanzar FraudShield y sigue.
- ⚠️ **Tutorial hell:** por cada hora de teoría, 2 de construir.
- ⚠️ **Costos GCP:** alertas de presupuesto, free tier, **apaga Cloud Composer/Cloud SQL** al terminar. BigQuery cobra por datos escaneados.
- ⚠️ **Alcance senior es grande:** las Semanas 6–8 (CI/CD, seguridad, observabilidad) son densas — reserva ahí tu mayor energía, no busques perfección sino "funciona y está documentado".
- ⚠️ **No subir datos/credenciales a Git** (`.gitignore` + Secret Manager).

**Reglas de oro**
1. **Todo a GitHub, siempre.**
2. **README primero**, documenta mientras construyes.
3. **Un proyecto, no doce.** Profundidad > amplitud.
4. **Habla el idioma del negocio** (impacto del fraude en $).
5. **Desarrolla local (gratis), despliega en nube (impresionante).**
6. **CRISP-DM y Ágil son vocabulario, no burocracia.**

---

## ✅ Resumen ejecutivo

En 9 semanas intensivas construyes **FraudShield**, una plataforma cloud de **detección de fraude bancario** que te obliga a aprender —usándolo— todo el stack del cargo **a nivel senior**: ingesta multi-fuente, ELT con **dbt** sobre **BigQuery**, orquestación con **Airflow**, modelado de fraude con **clases desbalanceadas** y explicabilidad, un **RAG** para consultas semánticas/cualitativas sobre narrativas de casos, y la capa de producción senior que tú añadiste — **MLOps + CI/CD + DevOps (Terraform), testing (código/datos/modelo), performance (Locust), seguridad de datos e IA (IAM, Secret Manager, DLP, OWASP LLM Top 10) y observabilidad (logging, alertas, drift con Evidently)** — todo desplegado en **GCP (Cloud Run)** con un **dashboard React**, gestionado bajo **CRISP-DM** y **Kanban**, y desarrollado de forma **híbrida** (experimentas gratis en tu RTX 4070 Super, despliegas en la nube). El resultado: un portafolio que cubre el 100% de los requisitos, los "plus", las prácticas senior, y que **complementa tu experiencia real en detección de fraude** — tu respuesta a casi cualquier pregunta de entrevista.

---

> **Manuales paso a paso:** ver carpeta [`manuales/`](./manuales/README.md). Cada semana tiene su manual a prueba de dummies.
