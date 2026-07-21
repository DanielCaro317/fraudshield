# FraudShield 🛡️🏦 (GCP)

Plataforma cloud-native de **detección de fraude bancario (Datos + IA)** para un departamento antifraude, construida en **Google Cloud Platform**.

> Parte del portafolio [Banking Fraud & AI](../README.md). Proyecto hermano: [`aws-banking-copilot/`](../aws-banking-copilot/) (RAG/Bedrock/Guardrails en AWS).

## Caso de uso
Analiza millones de transacciones bancarias para detectar fraude, y permite a los analistas hacer **consultas semánticas y cualitativas** (en lenguaje natural) sobre narrativas de casos y quejas de clientes.

## Arquitectura
Kaggle/CFPB (transacciones + quejas) → Cloud Storage (Data Lake) → BigQuery (Data Warehouse) → dbt (ELT, features de fraude) → Airflow (orquestación) → Vertex AI (modelo de detección de fraude + RAG) → Cloud Run (API de scoring + chat) → React (dashboard antifraude).

## Stack
Python · SQL · BigQuery · dbt · Apache Airflow (Cloud Composer) · scikit-learn / XGBoost · Vertex AI · RAG (embeddings + vector search) · FastAPI · Docker · Cloud Run · React.

## Estructura
- `extract/` — ingesta de transacciones y quejas al Data Lake
- `dbt_project/` — transformaciones ELT y features de fraude
- `dags/` — pipelines de Airflow
- `notebooks/` — EDA y modelado de detección de fraude
- `ml/` — entrenamiento del modelo de fraude
- `finetune/` — fine-tuning local (LoRA/QLoRA)
- `rag/` — asistente de consultas semánticas/cualitativas (RAG)
- `agents/` — Agente Investigador de Fraude (LangGraph)
- `eval/` — evaluación de RAG/LLM (RAGAS)
- `api/` — API de scoring + chat (FastAPI)
- `frontend/` — dashboard antifraude (React)
- `infra/` — infraestructura como código (Terraform)
- `manuales/` — manuales paso a paso (UI + CLI)

## Estado
🚧 En construcción — siguiendo metodología CRISP-DM. Entorno listo (Manual 00 ✅), en curso el Manual 01 (ingesta).
