# FraudShield 🛡️🏦

Plataforma **cloud-native de detección de fraude bancario + IA generativa (agentic)**, construida en **Google Cloud Platform**. Simula el flujo real de un departamento antifraude: ingiere millones de transacciones y narrativas de quejas de clientes, las transforma en features, entrena modelos de detección de fraude, ofrece un **asistente RAG** para consultas semánticas y un **Agente Investigador de Fraude (LangGraph)**, todo desplegado con prácticas de producción (CI/CD, seguridad, observabilidad).

> 🚧 **Estado:** en construcción, siguiendo una metodología **CRISP-DM** y un plan de aprendizaje intensivo. Cada componente tiene su **manual paso a paso** en [`manuales/`](./manuales/README.md).

---

## 🏗️ Arquitectura

```
 Kaggle/CFPB (transacciones + quejas)
        │
        ▼
 Cloud Storage (Data Lake) ──► BigQuery (Data Warehouse)
        │                            │
        │                       dbt (ELT, features de fraude)
        │                            │
   Airflow (orquestación) ───────────┤
                                      ├──► ML de fraude (BigQuery ML + XGBoost/SHAP)
                                      └──► RAG (embeddings + vector search sobre quejas)
                                                 │
                                     Agente Investigador de Fraude (LangGraph)
                                                 │
                              FastAPI + Docker ──► Cloud Run (API scoring + chat)
                                                 │
                                        React Dashboard (equipo antifraude)
```

## 🧰 Stack

Python · SQL · **BigQuery** · **dbt** · **Apache Airflow** (Cloud Composer) · scikit-learn / **XGBoost** · **RAG** (embeddings, ChromaDB/pgvector, hybrid search, re-ranking) · **RAGAS** (evaluación) · **LangChain / LangGraph** (agentes) · **MLflow / W&B** · **FastAPI** · **Docker** · **Cloud Run** · **GitHub Actions** (CI/CD) · **Terraform** · React · (multi-cloud: GCP principal, AWS por equivalencia).

## 📂 Estructura del repositorio

```
├── manuales/           # 📚 Manuales paso a paso (empieza aquí)
├── extract/            # Ingesta de datos al Data Lake
├── dbt_project/        # Transformaciones ELT y features de fraude
├── dags/               # Pipelines de Airflow
├── notebooks/          # EDA y modelado
├── ml/                 # Entrenamiento del modelo de fraude
├── finetune/           # Fine-tuning local (LoRA/QLoRA)
├── rag/                # Asistente RAG (consultas semánticas)
├── agents/             # Agente Investigador de Fraude (LangGraph)
├── eval/               # Evaluación de RAG/LLM (RAGAS)
├── api/                # API de scoring + chat (FastAPI)
├── frontend/           # Dashboard antifraude (React)
├── infra/              # Infraestructura como código (Terraform)
└── docs/               # Documentación y decisiones de arquitectura
```
> Las carpetas de código se crean al seguir los manuales. Este repo arranca con la **documentación y los manuales**.

## 🚀 Cómo empezar

1. Lee el índice de manuales: [`manuales/README.md`](./manuales/README.md).
2. Sigue en orden desde el **Manual 00** (configuración del entorno en la nube).
3. Cada manual es **a prueba de dummies**: comandos exactos, checkpoints y solución de problemas.

## 📖 Documentación de aprendizaje

- [Plan de aprendizaje — Ingeniero ML (Ceiba)](./PLAN_APRENDIZAJE_CEIBA_ML.md)
- [Diagnóstico y plan — Senior AI Engineer (Proxify)](./PLAN_APRENDIZAJE_PROXIFY_AI_ENGINEER.md)
- [Preparación de entrevista técnica (Proxify)](./PREPARACION_ENTREVISTA_TECNICA_PROXIFY.md)

---

_Proyecto de portafolio orientado a roles de Ingeniería de ML / Datos e IA (GenAI/LLMs)._
