# 📚 Manuales — Banking Policy Copilot (AWS)

> Manuales **paso a paso, a prueba de dummies**, para construir de cero un **asistente RAG de producción sobre Amazon Bedrock**, cubriendo lo que piden las vacantes reales de *AWS GenAI / RAG Engineer*: RAG bien entendido, Bedrock nativo, **Guardrails como módulo completo**, evaluación rigurosa, despliegue real y portabilidad multi-cloud.
>
> **Filosofía:** primero entender (RAG desde cero), luego Bedrock gestionado, luego seguridad y evaluación, luego producción. **Un solo proyecto, llevado progresivamente a nivel profesional** — no cinco chatbots sueltos.
>
> 🖱️ / ⌨️ **Formato doble camino (UI + CLI):** cada paso se explica por la **Consola web** y con su **comando/código** equivalente. Puedes avanzar solo con la UI y usar el CLI como músculo para entrevistas.

---

## 🗺️ Ruta (orden recomendado)

Basada en el diagnóstico de aprendizaje (`../../docs/planeacion/`): **RAG esencial → Bedrock nativo → LangChain sobre Bedrock → seguridad/evaluación → producción → portar a GCP.**

| # | Manual | Qué aprendes | Estado |
|---|--------|--------------|--------|
| 00 | [Configuración del entorno AWS](./00_entorno_aws.md) | Cuenta segura, IAM Identity Center, región, Budgets, CloudShell/CLI/boto3, **acceso a modelos Bedrock**, probar Claude | ✅ |
| 01 | [RAG desde cero en Python](./01_rag_desde_cero_python.md) | Documentos → extracción → **chunking** → **embeddings** (Titan) → vector store (NumPy) → top-k → prompt → **respuesta con citas** (Claude). Entender chunk size, overlap, similitud, semántica/keyword/híbrida | ✅ |
| 02 | [Bedrock Knowledge Bases + vector store](./02_bedrock_kb_opensearch.md) | S3 → **Knowledge Base** → **OpenSearch Serverless / S3 Vectors** → Titan Embeddings. RAG gestionado vs a mano. **Elección de vector store + control de costos** | ✅ |
| 03 | [Retrieve / RetrieveAndGenerate con boto3](./03_retrieve_generate_boto3.md) | `RetrieveAndGenerate` (gestionado) vs `Retrieve` + `Converse` (controlado), **filtros por metadata**, búsqueda híbrida, citas, lógica de rechazo, sesiones | ✅ |
| 04 | [**Guardrails + seguridad (Bedrock)**](./04_guardrails_seguridad.md) 🔒 | **Bedrock Guardrails** completo (6 políticas): content filters, prompt-attack, denied topics, PII, **contextual grounding**, automated reasoning + **ApplyGuardrail** + defensa en profundidad (OWASP LLM, IAM mínimo, logging, aislamiento del contexto) | ✅ |
| 05 | [Evaluación del RAG](./05_evaluacion_dataset.md) | Dataset dorado (respondibles/no/ambiguas/adversariales/metadata). Métricas **retrieval** (hit rate, MRR) vs **generación** (faithfulness, relevancia, citas, rechazo) con **Bedrock Evaluations** + **RAGAS**, eval de Guardrails (FP/FN) y operación (p50/p95, tokens, costo) | ✅ |
| 06 | LangChain sobre Bedrock | Reimplementar el mismo RAG con `ChatBedrockConverse`, `BedrockEmbeddings`, `AmazonKnowledgeBasesRetriever`, chains (LCEL) + tracing. Comparar boto3 nativo vs LangChain | ⏳ |
| 07 | Despliegue real | API Gateway → Lambda → Bedrock/KB, IaC (**CDK o Terraform**), CloudWatch (logs/métricas/costo), CI/CD, manejo de errores/timeouts/retries | ⏳ |
| 08 | Portabilidad a GCP 🔁 | Portar el mismo sistema: S3→Cloud Storage, Bedrock→Vertex/Gemini, KB→Vertex AI RAG Engine, Guardrails→Model Armor, CloudWatch→Cloud Logging. **El puente multi-cloud** | ⏳ |

> ✅ = disponible · ⏳ = en construcción
>
> 🔒 Manual 04 (Guardrails) es el diferenciador clave: responde con evidencia la pregunta *"¿has usado Guardrails?"* que hoy no puedes sostener.

---

## 🧭 Cómo usar estos manuales

1. **Sigue el orden.** Cada manual construye sobre el anterior.
2. **Elige tu camino: 🖱️ UI o ⌨️ CLI.** Ambos están en cada paso.
3. **No saltes los ✅ Checkpoint.**
4. **Apaga/borra recursos caros** (OpenSearch Serverless) al terminar cada sesión — te lo recuerdo en cada manual.
5. **Commit a GitHub** al terminar cada manual.

## 💰 Sobre costos

- Cuentas nuevas (desde 15-jul-2025): hasta **USD 200 en créditos**. Ver Manual 00 §3.
- **Bedrock** se paga por token; **OpenSearch Serverless** tiene costo mínimo por hora. **AWS Budgets es obligatorio** (Manual 00 §5).

## 📌 Convenciones

- 🖱️ **UI** (clics en la consola) · ⌨️ **CLI** (comando equivalente)
- ✅ **Checkpoint** · 🛟 **Solución de problemas** · 💡 **Tip / por qué** · 📖 **Glosario** · ⚠️ **Cuidado**
- 🔁 **Equivalente en GCP** (para tu pitch multi-cloud)
