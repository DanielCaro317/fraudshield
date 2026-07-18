# 📚 Manuales — Proyecto FraudShield (Cloud-Native en GCP)

> Manuales paso a paso, **a prueba de dummies**, para construir de cero una plataforma de **Detección de Fraude Bancario** completamente en la nube (Google Cloud Platform), cubriendo el 100% de los requisitos del cargo de **Ingeniero Machine Learning** de Ceiba Software.
>
> **Filosofía:** Todo en la nube. Casi nada se instala en tu PC. Sigue los manuales en orden; cada uno asume que completaste el anterior.
>
> 🖱️ / ⌨️ **Formato doble camino (UI + CLI):** cada paso operativo se explica **primero por la Consola web (clic por clic)** y, al lado, con su **comando equivalente en Cloud Shell**. Puedes completar los manuales **solo con la interfaz gráfica** si el terminal aún se te hace cuesta arriba, y usar el CLI como referencia y "músculo" para entrevistas. Donde una herramienta es inevitablemente de código (dbt, Airflow, RAG, agentes) te doy la vía **más visual posible** (el editor gráfico de Cloud Shell/VS Code, notebooks de Vertex AI, la web de Airflow, dashboards). Lee el bloque **"🖱️ / ⌨️ Cómo leer este manual"** al inicio de cada uno.

---

## 🎯 El proyecto: "FraudShield"

Una plataforma de analítica y detección de fraude **para el departamento de fraude de un banco**, que simula el flujo real de trabajo de un equipo antifraude:

1. **Ingiere** datos transaccionales masivos (millones de transacciones bancarias) + narrativas cualitativas de casos/quejas de clientes, desde fuentes públicas (Kaggle / CFPB).
2. Los almacena en un **Data Lake** (Cloud Storage) y un **Data Warehouse** (BigQuery).
3. Los **transforma** con dbt (ELT) en features y marcos de detección de fraude.
4. **Orquesta** todo el flujo con Airflow (Cloud Composer).
5. Entrena un **modelo de detección de fraude** (clasificación con clases desbalanceadas — BigQuery ML + Vertex AI).
6. Ofrece un asistente de **consultas semánticas y cualitativas (RAG, evaluado con RAGAS)** que permite a un analista preguntar en lenguaje natural sobre patrones, casos y quejas.
7. Incluye un **Agente Investigador de Fraude (LangGraph)** que, dado un caso, consulta la transacción, la puntúa, busca quejas similares (RAG) y redacta un borrador de reporte de actividad sospechosa (SAR) — workflow agentic multi-paso.
8. Se **despliega** como API (Cloud Run / AWS) con CI/CD y eval-gates + un **dashboard en React** para el equipo antifraude.

> 💡 **Por qué este caso (sirve para DOS vacantes):**
> - **Ceiba (Ingeniero ML):** demuestra el perfil híbrido Data Engineer + ML/AI (dbt, Airflow, SQL, ML, GCP).
> - **Proxify (Senior AI Engineer):** demuestra IA de producción senior (RAG evaluado, **agentes/LangGraph**, prompt engineering, IR avanzado, LLMOps, seguridad de IA, multi-cloud, fine-tuning).
> - Complementa experiencia real en detección de fraude bancario (tipo Scotiabank). **Un solo super-proyecto, dos pitches.** Ver [`../PLAN_APRENDIZAJE_PROXIFY_AI_ENGINEER.md`](../PLAN_APRENDIZAJE_PROXIFY_AI_ENGINEER.md).

---

## 🗺️ Índice de manuales

| # | Manual | Qué aprendes | Cubre (Ceiba / **Proxify**) | Estado |
|---|--------|--------------|-------------------------------|--------|
| 00 | [Configuración del entorno](./00_configuracion_entorno_nube.md) | GCP (Cloud Shell, gcloud, APIs, billing/alertas) + **AWS básico (multi-cloud)** + **entorno local (Ollama/Docker, GPU)** + GitHub | Base de todo | ✅ |
| 01 | [Ingesta de datos y Data Lake](./01_ingesta_datos_y_data_lake.md) | Transacciones (PaySim) + quejas (CFPB) → Cloud Storage (Data Lake) → BigQuery (DW); datos estructurados y no estructurados | Prospección de fuentes, gran volumen, SQL | ✅ |
| 02 | [Transformación ELT con dbt](./02_transformacion_elt_dbt.md) | dbt + BigQuery, staging/intermediate/marts, **features de fraude**, tests de calidad, lineage | ETL/ELT, dbt, SQL, calidad | ✅ |
| 03 | [Orquestación con Airflow](./03_orquestacion_airflow.md) | DAGs, scheduling, reintentos, idempotencia, automatización del pipeline, validación de datos, demo Cloud Composer | Airflow, automatización | ✅ |
| 04 | [Modelado de ML (detección de fraude)](./04_modelado_ml_fraude.md) | EDA, **clases desbalanceadas**, BigQuery ML baseline, XGBoost, métricas (AUC-PR), umbral, explicabilidad (SHAP), CRISP-DM, fuga de datos | ML tradicional y avanzado | ✅ |
| **04B** 🆕 | **Fine-tuning local (PEFT)** | RAG vs fine-tuning vs prompting, **LoRA/QLoRA en tu RTX 4070 Super**, datos y evaluación del modelo afinado | **Proxify: fine-tuning/training** | ⏳ |
| 05 | [IA Generativa y RAG (ampliado)](./05_rag_consultas_semanticas.md) | Embeddings, ChromaDB, RAG sobre quejas con citas + **hybrid search, re-ranking, prompt engineering, EVALUACIÓN con RAGAS, tracing (Langfuse)** | LLMs, RAG · **Proxify: IR avanzado, eval, prompt eng.** | ✅ |
| **05B** 🆕 | [**Agentes y workflows (LangGraph)**](./05B_agentes_langgraph.md) | Agentes ReAct, tool calling, grafos de estado, multi-paso, human-in-the-loop → **Agente Investigador de Fraude** | **Proxify: AI agents & workflows** | ✅ |
| 06 | MLOps + CI/CD + Testing (ampliado) | MLflow/Vertex Registry, FastAPI, Docker, Artifact Registry, **GitHub Actions con eval-gates (RAGAS en CI)**, Terraform (IaC), testing código/datos/modelo, **W&B**, **DevOps vs MLOps vs LLMOps** | MLOps, despliegue · **Proxify: CI/CD, eval-gates** | ⏳ |
| 07 | Despliegue + Performance (ampliado) | Cloud Run (CD automático) + dashboard React + pruebas de carga (Locust/k6) + **despliegue alternativo en AWS (Bedrock/ECS), Kubernetes, streaming/async/escala de LLM** | Despliegue, React, performance · **Proxify: escala, multi-cloud** | ⏳ |
| 08 | Seguridad (datos + IA) y Observabilidad (ampliado) | IAM, Secret Manager, DLP/PII, **OWASP LLM Top 10 + guardrails avanzados (Llama Guard/NeMo), defensa de prompt injection**, Cloud Logging/Monitoring, drift (Evidently), rollback | Seguridad, observabilidad · **Proxify: seguridad de IA** | ⏳ |
| 09 | Integración, storytelling y entrevista | README maestro, narrativa antifraude, Ágil/CRISP-DM, glosario, **prep entrevista Ceiba + Proxify** | Comunicación, metodología | ⏳ |

> ✅ = disponible · ⏳ = en construcción · 🆕 = manual nuevo del delta Proxify
>
> 🆕 **Bloque senior + Proxify (fusionado):** CI/CD/eval-gates, DevOps/IaC, seguridad de datos e IA, testing en 3 niveles, performance, observabilidad, **agentes (LangGraph)**, **fine-tuning** y **multi-cloud** están repartidos en los Manuales **00, 04B, 05, 05B, 06, 07 y 08**.
>
> 📄 **Prep de entrevista técnica Proxify:** ver [`../PREPARACION_ENTREVISTA_TECNICA_PROXIFY.md`](../PREPARACION_ENTREVISTA_TECNICA_PROXIFY.md) (banco de preguntas + guiones en inglés).

---

## 🧭 Cómo usar estos manuales

1. **Sigue el orden.** Cada manual construye sobre el anterior.
2. **Elige tu camino: 🖱️ UI o ⌨️ CLI.** Cada paso trae ambos. Si eres semi-junior, haz primero la **UI** para entender qué pasa; luego, si quieres, repite por CLI para ganar soltura (lo esperan en entrevista).
3. **No saltes los "✅ Checkpoint".** Son verificaciones para confirmar que vas bien antes de seguir.
4. **Copia los comandos/valores tal cual**, salvo donde diga `<REEMPLAZAR>`.
5. Si algo falla, ve a la sección **"🛟 Solución de problemas"** al final de cada manual.
6. Al terminar cada manual, haz **commit a GitHub** (te lo recuerdo en cada uno). Lo que no está en GitHub, no existe para el reclutador.

> 💡 **¿Se puede hacer todo por la interfaz gráfica, como en AWS?** En gran parte **sí**: crear buckets, cargar a BigQuery, correr SQL, entrenar modelos con BigQuery ML, operar Airflow y ver dashboards son 100% por clics. Lo que es **código por naturaleza** (dbt, los DAGs de Airflow, RAG y agentes) no tiene un botón equivalente **en ninguna nube** — ahí te damos la forma más visual (editores gráficos, notebooks) y el código explicado línea por línea.

---

## 🏗️ Arquitectura del sistema (visión global)

```
   FUENTES                      GCP (todo en la nube)
   ├─ PaySim (transacciones) ─┐
   │   ~6.3M filas            │   Cloud Storage        BigQuery (DW)
   ├─ CFPB (quejas/texto) ────┼──►  (Data Lake)  ───►  fraud_raw / marts
   └─ (futuras: APIs banco)   │        ▲                    │
                              │        │   AIRFLOW          ▼
                              │        └── (Composer) ──► dbt (ELT, features)
                              │                              │
                              │            ┌─────────────────┴───────────────┐
                              │            ▼                                 ▼
                              │   ML detección de fraude          RAG consultas semánticas
                              │   (BQ ML / Vertex AI)             (embeddings + vector search
                              │            │                       sobre casos/quejas)
                              │            ▼                                 │
                              │   Vertex AI / MLflow (registro)             │
                              │            │                                 │
                              │            ▼                                 ▼
                              │   FastAPI + Docker ──► Cloud Run (API de scoring + chat)
                              │                          │
                              └──────────────────────────┼──────────────────►
                                                         ▼
                                          React Dashboard (equipo antifraude)
```

---

## 💰 Sobre costos (importante)

- GCP da **USD 300 de crédito gratis por 90 días** + un **free tier permanente** (BigQuery: 1 TB de consultas/mes y 10 GB de almacenamiento gratis; Cloud Storage: 5 GB; etc.).
- En el **Manual 00** configuras **alertas de presupuesto** para no llevarte sorpresas.
- Regla: **apaga/elimina recursos caros** (Cloud Composer, Cloud SQL) cuando no los uses. Cada manual te dice cómo.

---

## 📌 Convenciones de notación

- 🖱️ **Por la Consola (UI)** → hazlo con clics en la consola web (`console.cloud.google.com`).
- ⌨️ **Equivalente en CLI** → el mismo resultado con un comando en Cloud Shell.
- `comando a ejecutar` → cópialo en Cloud Shell (o en la terminal de tu PC cuando el manual lo indique).
- `<REEMPLAZAR>` → cámbialo por tu valor (sin los `< >`).
- **✅ Checkpoint** → punto de verificación obligatorio.
- **🛟** → solución de problemas.
- **💡** → tip o explicación del "por qué".
- **📖** → glosario / concepto clave.
- **🔁** → equivalente en AWS (multi-cloud).
