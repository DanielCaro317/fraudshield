# 🛡️🏦 Banking Fraud & AI — Portafolio de dos proyectos (AWS + GCP)

> Repositorio-portafolio con **dos proyectos complementarios del mismo dominio (banca / fraude)**, cada uno enfocado en una nube y una metodología distinta, que **juntos** cubren todo el perfil que busco demostrar: **AI Engineering de producción (RAG/LLM/agentes)** y **Data Engineering + ML clásico**.

## 🎯 Por qué dos proyectos y no uno

No son el mismo producto: son dos sistemas que se complementan y comparten el dominio bancario/fraude. Separarlos deja que **cada uno sea profundo en su carril** en vez de dos cosas superficiales.

| | [`aws-banking-copilot/`](./aws-banking-copilot/) | [`gcp-fraudshield/`](./gcp-fraudshield/) |
|---|---|---|
| **Producto** | *Banking Policy Copilot* — asistente RAG sobre políticas, procedimientos y tipologías de fraude | *FraudShield* — plataforma de detección de fraude transaccional + ML |
| **Núcleo técnico** | Bedrock Knowledge Bases · OpenSearch Serverless · **Guardrails** · evaluación · LangChain-sobre-Bedrock | dbt · Airflow · BigQuery ML · XGBoost · Vertex AI |
| **Metodología** | RAG-engineering / LLM en producción / defensa-en-profundidad | Data-eng / MLOps / CRISP-DM |
| **Nube** | **AWS** (con capítulo de portabilidad a GCP) | **GCP** |
| **Vacante que ataca** | Senior AI Engineer (Proxify) · roles "AWS GenAI/RAG Engineer" | Ingeniero ML (Ceiba, GCP-favorable) |

## 🗣️ La narrativa (un solo relato, dos pitches)

> *"He construido dos sistemas de banca antifraude: una **plataforma de detección de fraude transaccional con ML en GCP** (dbt, Airflow, BigQuery ML, XGBoost) y un **copilot de políticas bancarias basado en RAG en AWS** (Bedrock Knowledge Bases, OpenSearch, Guardrails, evaluación rigurosa), que además porté a GCP para comparar Bedrock↔Vertex y Guardrails↔Model Armor."*

- Para **Ceiba** → resalto: data engineering, dbt/Airflow, ML, GCP, CRISP-DM. → [`gcp-fraudshield/`](./gcp-fraudshield/)
- Para **Proxify / AWS** → resalto: RAG evaluado, Bedrock nativo, Guardrails, seguridad de IA, portabilidad multi-cloud. → [`aws-banking-copilot/`](./aws-banking-copilot/)

## 📂 Estructura del repo

```
.
├── aws-banking-copilot/     ← Proyecto 1: RAG/Bedrock/Guardrails (AWS)  [EN CONSTRUCCIÓN 🚧]
│   └── manuales/            ← manuales nuevos, extensos, paso a paso (UI + CLI)
├── gcp-fraudshield/         ← Proyecto 2: Data + ML (GCP)  [manuales 00–05B listos]
│   └── manuales/
└── docs/                    ← COMPARTIDO: planeación, diagnóstico, prep entrevistas, job specs
```

## 🧭 Estado y punto actual

- **GCP (FraudShield):** entorno montado (Manual 00 ✅). Voy por el **Manual 01** (ingesta). Manuales 00–05B escritos.
- **AWS (Banking Copilot):** proyecto nuevo. Empezando por el entorno (Manual 00). Todos los manuales son nuevos.

> 📄 Diagnóstico y estrategia de aprendizaje: [`docs/planeacion/`](./docs/planeacion/) (incluye el análisis del "Camino en IA y RAG" y los planes Ceiba/Proxify).
