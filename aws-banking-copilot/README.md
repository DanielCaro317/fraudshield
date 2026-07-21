# 🏦🤖 Banking Policy Copilot (AWS)

Asistente **RAG de producción** sobre políticas bancarias, procedimientos operativos y tipologías de fraude, construido **nativo en AWS (Amazon Bedrock)** con foco en **evaluación rigurosa, seguridad (Guardrails + defensa en profundidad) y despliegue real**.

> Parte del portafolio [Banking Fraud & AI](../README.md). Proyecto hermano: [`gcp-fraudshield/`](../gcp-fraudshield/) (detección de fraude ML en GCP).

## 🎯 Qué demuestra

Este proyecto está diseñado para responder con autoridad — y con **evidencia en el repo** — las preguntas que un reclutador de un rol *AWS GenAI / RAG Engineer* realmente hace:

- *"¿Entiendes RAG por debajo?"* → implementación **desde cero con Python** antes de cualquier framework.
- *"¿Bedrock nativo?"* → S3 → **Knowledge Bases** → **OpenSearch Serverless** → Titan Embeddings → `Retrieve` / `RetrieveAndGenerate` con **boto3**.
- *"¿Has usado Guardrails?"* → **módulo completo**, no una pestaña: content filters, prompt-attack detection, denied topics, PII/sensitive-info filters, contextual grounding + defensa en profundidad (IAM mínimo privilegio, logging).
- *"¿Cómo lo evalúas?"* → dataset de 80–100 preguntas (respondibles / no respondibles / ambiguas / adversariales / con filtro de metadata) y métricas separadas de **retrieval** vs **generación**.
- *"¿LangChain?"* → segunda implementación **LangChain-sobre-Bedrock** para comparar velocidad, portabilidad y trazabilidad.
- *"¿Multi-cloud?"* → capítulo de **portabilidad a GCP** (Bedrock↔Vertex, Guardrails↔Model Armor, OpenSearch↔Vertex Vector Search).

## 🏗️ Arquitectura objetivo

```
Documentos (políticas/fraude, con metadata por fecha/producto/país)
        │
        ▼
   Amazon S3 ──► Bedrock Knowledge Base ──► OpenSearch Serverless (vector store)
                        │  (Titan Embeddings)
                        ▼
          Retrieve / RetrieveAndGenerate (boto3)
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
   Bedrock Guardrails   Modelo (Claude)   Citas + lógica de rechazo
        │               │
        ▼               ▼
   FastAPI ──► API Gateway ──► Lambda ──► (CloudWatch: logs, métricas, costo)
        │
        ▼
   Evaluación (retrieval + generación) · IaC (CDK/Terraform) · CI/CD
```

## 📂 Estructura
- `manuales/` — manuales paso a paso (UI + CLI), extensos
- `ingestion/` — carga de documentos a S3, parsing, chunking, metadata
- `retrieval/` — Knowledge Bases, OpenSearch, `Retrieve`/`RetrieveAndGenerate`
- `guardrails/` — configuración y pruebas de Bedrock Guardrails
- `eval/` — dataset dorado y scripts de evaluación (retrieval + generación)
- `api/` — API de consulta (FastAPI)
- `langchain/` — variante LangChain-sobre-Bedrock (comparación)
- `infra/` — infraestructura como código (AWS CDK o Terraform)

## Estado
🚧 En construcción. Empezando por el entorno AWS (Manual 00). Ver [`manuales/README.md`](./manuales/README.md).
