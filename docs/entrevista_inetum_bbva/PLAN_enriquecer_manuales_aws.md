# 📈 PLAN · Enriquecer el proyecto AWS con los gaps (segundo track)

> **Objetivo:** que al recorrer los manuales AWS **pases naturalmente por los gaps** (Spark, Glue, Athena, streaming, SageMaker, Kubeflow, PyTorch). Convierte el "Banking **Copilot**" (RAG documental) en una "Banking **AI Platform**" (datos + ML + GenAI), que es justo lo que pide la vacante.
>
> ⚠️ **Este track es POST-entrevista.** No es estudiable antes de mañana. Para mañana usa el dossier. Esto es la hoja de ruta para subir de nivel de verdad después.

---

## Idea: extender, no reescribir

El proyecto AWS hoy es un RAG documental (Manuales 00–08). Le falta la **capa de datos a escala** y la **capa de ML clásico**, que comparten el mismo dominio bancario. Se añaden como manuales nuevos coherentes con los existentes (mismo estilo UI+CLI, mismo caso).

## Dónde entra cada gap

| Gap | Cómo se integra | Manual (propuesto) |
|---|---|---|
| **S3 a escala + Glue (Spark) + Glue Data Catalog** | Nueva **capa de datos** que alimenta la KB *y* el modelo de fraude: ingesta y ETL distribuido del data lake bancario | 🆕 **01B · Data lake y ETL a escala (S3 + Glue + Spark)** |
| **Amazon Athena** | Consultas SQL serverless sobre el lake (exploración, features, auditoría) | dentro de 01B (sección Athena) |
| **Apache Spark** | El motor detrás de Glue; una sección de PySpark + variante EMR | dentro de 01B |
| **SageMaker + PyTorch/TF + explicabilidad (Clarify)** | El **gemelo ML-clásico** del RAG: entrenar un modelo de fraude en AWS, registrarlo, servirlo y explicarlo (Clarify/SHAP) | 🆕 **09 · Detección de fraude en AWS (SageMaker)** |
| **Kinesis / Kafka (streaming)** | Scoring de fraude **en tiempo real**: evento → puntúa → alerta | 🆕 **10 · Streaming y scoring en tiempo real (Kinesis)** |
| **Kubeflow / MLOps a escala / Prefect** | Comparativa de plataformas MLOps: SageMaker Pipelines vs Kubeflow (EKS) vs MLflow; Airflow vs Prefect | 🆕 **11 · MLOps/LLMOps a escala** (o ampliar Manual 07) |

## Arquitectura objetivo ampliada

```
Batch:  fuentes → S3 → Glue(Spark) → Glue Catalog → Athena / features
Stream: eventos → Kinesis → scoring tiempo real → alertas
ML:     features → SageMaker (train/registry/serving/Clarify) → modelo fraude
GenAI:  S3 → Bedrock KB → Guardrails → Claude → copiloto (lo que YA tienes)
Cross:  MLOps/LLMOps (SageMaker Pipelines/Kubeflow, CI/CD, eval-gates) · Gobernanza (IAM/KMS/DLP/audit)
```

## Orden sugerido (con el método de la biblioteca)

Sigue la [estrategia de estudio](../../biblioteca/estrategia-de-estudio.md): por cada gap → 🧠 idea central (ya en los briefs) → 📘 doc oficial → construir el manual → 🔀 variantes → registrar decisiones/errores.

**Prioridad post-entrevista** (por impacto para este perfil):
1. **09 · SageMaker (fraude)** — es tu ML clásico llevado a AWS; cierra "plataforma ML" + explicabilidad/gobernanza.
2. **01B · Glue/Spark/Athena** — la capa de datos a escala que más se repite en la vacante.
3. **10 · Kinesis (streaming)** — el caso estrella de banca (fraude en tiempo real).
4. **11 · MLOps a escala** — Kubeflow/SageMaker Pipelines/Prefect como cierre de gobernanza.

## Siguiente paso concreto

Cuando pase la entrevista, empezamos por el **mapa de documentación** de estos 4 temas nuevos en [`biblioteca/aws-banking-copilot/mapa-documentacion.md`](../../biblioteca/aws-banking-copilot/mapa-documentacion.md) (nuevas capas), y de ahí a los manuales. Así primero decides *qué estudiar* y luego construyes.

> Resultado final: un solo proyecto AWS que demuestra **datos a escala + ML clásico + GenAI/RAG + streaming + MLOps + gobernanza** — exactamente el perfil "ML Sr. Experto" de la vacante.
