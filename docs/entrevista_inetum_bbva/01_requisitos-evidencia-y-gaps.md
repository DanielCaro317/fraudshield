# 01 · Requisitos ↔ tu evidencia (y los gaps)

> Tu ancla de confianza. La mayoría de lo que piden **ya lo construiste**. Aquí está el mapeo exacto + qué decir.

---

## ✅ Lo que YA tienes (lidera con esto)

| Requisito de la vacante | Tu evidencia (dónde) | Soundbite para la entrevista |
|---|---|---|
| **Python avanzado** | Ambos proyectos (ingesta, ML, RAG, API) | *"Python es mi lenguaje principal end-to-end: ingesta, modelado, RAG y APIs."* |
| **FastAPI** | `aws-banking-copilot/api/`, Manual 07 | *"Expongo modelos y RAG como APIs con FastAPI, con validación Pydantic y streaming."* |
| **LangChain / tooling LLM** | AWS Manual 06 (`ChatBedrockConverse`, retriever de KB, LCEL) + LangGraph (GCP) | *"Implementé el mismo RAG en boto3 nativo y en LangChain para comparar control vs velocidad."* |
| **Soluciones LLM empresariales / RAG** | **AWS Banking Copilot completo** (Manuales 00–08) | *"Construí un copiloto RAG de políticas bancarias sobre Bedrock, de cero a producción."* |
| **MLOps / LLMOps** | Manual 07 (CI/CD, eval-gates), MLflow, monitoreo | *"Distingo DevOps, MLOps y LLMOps: para LLM añado eval-gates y observabilidad de calidad, no solo de sistema."* |
| **Gobernanza / cumplimiento** ⭐ | **Manual 04 (Guardrails: 6 políticas + Automated Reasoning) + IAM mínimo + DLP/PII + evaluación** | *"En banca, la gobernanza pesa tanto como el modelo: Guardrails, filtrado de PII, grounding contra alucinaciones y evaluación con umbrales."* |
| **AWS** | Bedrock, S3, OpenSearch/S3 Vectors, Lambda, API GW, CloudWatch (Manuales 00–08) | *"Trabajo AWS nativo: Bedrock para GenAI, y el patrón serverless S3→Lambda→API Gateway."* |
| **IaC (Terraform/CloudFormation)** | Manual 07 (CDK o Terraform) | *"Infra como código con Terraform/CDK; nada se crea a mano, todo revisable en PR."* |
| **Airflow (o Prefect)** | GCP Manual 03 (DAGs, idempotencia, reintentos) | *"Orquesto pipelines con Airflow: DAGs idempotentes, reintentos y scheduling."* |
| **CI/CD** | Manual 07 (GitHub Actions + OIDC + eval-gates) | *"CI/CD con OIDC (sin claves estáticas) y una puerta de calidad que bloquea el deploy si baja la métrica del RAG."* |
| **CloudWatch / monitoreo** | Manual 07 (logs, métricas, costo por token) | *"Observo latencia, errores y costo por token; para el LLM añado tracing de calidad."* |
| **Optimización de costos** | Control de costos en KB/OpenSearch, S3 Vectors, Budgets | *"Diseño con el costo en mente: p. ej. S3 Vectors vs OpenSearch según frecuencia de consulta."* |

> **Tu ML clásico (GCP):** detección de fraude con clases desbalanceadas, XGBoost, AUC-PR, SHAP, CRISP-DM. Úsalo si preguntan por ML tabular o explicabilidad — **el fraude + explicabilidad es oro en banca**.

---

## ⚠️ Los GAPS (lo nuevo — conversarlo, no fingir dominio)

El detalle profundo de cada uno está en **[02 · Briefs técnicos](./02_briefs-tecnicos-gaps.md)**. Resumen y a qué se parece de lo que ya sabes:

| Gap | Qué es (una línea) | A qué equivale de lo tuyo |
|---|---|---|
| **Apache Spark** | motor de cómputo distribuido para datos masivos | pandas/SQL, pero repartido en un clúster |
| **AWS Glue** | ETL serverless (corre Spark por debajo) + Data Catalog | dbt/ingesta, versión AWS gestionada |
| **Amazon Athena** | SQL serverless sobre S3 (paga por escaneo) | BigQuery (mismo modelo de "pago por lo escaneado") |
| **Kinesis / Kafka** | ingesta y procesamiento de datos en **streaming** | tus pipelines batch, pero en tiempo real |
| **SageMaker** | plataforma ML gestionada de AWS (train, registry, serving, monitor) | Vertex AI (su gemelo en GCP) |
| **Kubeflow** | MLOps sobre Kubernetes (pipelines, serving) | MLflow + orquestación, pero nativo K8s |
| **TensorFlow / PyTorch** | frameworks de deep learning | ya rozas PyTorch en tu fine-tuning (PEFT/LoRA) |
| **Prefect** | orquestador moderno (alternativa a Airflow) | Airflow, más pythónico y dinámico |

## 🎙️ Cómo posicionar un gap (plantilla honesta)

> *"[Herramienta] no la he llevado a producción, pero conozco el concepto y su equivalente que sí construí: [equivalente]. En este proyecto la usaría para [caso], y la elegiría sobre [alternativa] cuando [criterio]."*

Ejemplo real:
> *"Spark no lo he operado en clúster, pero domino el procesamiento de datos a gran escala con SQL en BigQuery y transformaciones con dbt. En AWS, Spark vía Glue sería mi vía para ETL distribuido; Athena para consultas ad-hoc serverless. El modelo mental —transformaciones perezosas, particionado, evitar shuffles— lo tengo del mundo de datos columnar."*

---

## 🧩 La foto de arquitectura que debes poder dibujar

Si te piden "diseña una plataforma de IA para el banco en AWS", esta es tu columna vertebral (mezcla lo que tienes + gaps):

```
Fuentes (core bancario, eventos)                     GOBERNANZA (transversal)
   │                          │                       IAM mínimo · KMS · DLP/PII
   ▼ batch                    ▼ streaming              CloudTrail · Guardrails
 S3 (data lake) ◄─ Glue ETL   Kinesis/Kafka            Model governance / audit
   │   (Spark)                  │
   ▼                           ▼
 Glue Data Catalog ──► Athena (SQL ad-hoc)     Feature Store
   │                                              │
   ▼                                              ▼
 dbt/Spark (features) ──► SageMaker (train/registry/serving)  ── modelo fraude/riesgo
   │                                              │
   ▼                                              ▼
 Bedrock KB (RAG) ──► Guardrails ──► Claude ──► API (Lambda/API GW) ──► app
   │                                              │
   └──────── MLOps/LLMOps: CI/CD · eval-gates · CloudWatch · MLflow/SageMaker Monitor ──────┘
```

> Practica dibujar esto en 2 minutos. Demuestra que ves el **sistema completo**, no piezas sueltas.
