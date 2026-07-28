# 🗺️ Mapa de documentación — AWS Banking Policy Copilot

> **Proyecto:** asistente **RAG de producción** sobre políticas bancarias y tipologías de fraude, nativo en **Amazon Bedrock**, con foco en evaluación rigurosa, seguridad (Guardrails + defensa en profundidad) y despliegue real.
> **Cómo leerlo:** esta es la capa de *"qué estudiar, en qué orden y por qué"* que envuelve los [manuales](../../aws-banking-copilot/manuales/) (la *implementación*). Lee la ficha **antes** de construir el manual, y vuelve a ella para romper y reconstruir con una variante.
> **Verificado:** jul-2026.

### Anatomía de cada ficha
- **🧠 Idea central** — el modelo mental en 2-4 frases: qué es *de verdad* y por qué está en el proyecto.
- **🎯 Ruta de lectura** — por dónde empezar, en qué orden, qué leer a fondo y qué saltar, con **⏱️ tiempo estimado** de estudio (~8 h/día).
- **📘 Documentación oficial** — **①** esencial · **②** referencia · **③** avanzada · 📚 **libros** (nombre + autor) · 📄 **papers** · 🎓 **curso** (solo si la doc no basta) · 🔀 **decisiones y variantes**.

> 🔁 El símbolo marca el **equivalente en GCP** — este proyecto es hermano de [`gcp-fraudshield`](../gcp-fraudshield/mapa-documentacion.md); los fundamentos compartidos (Python, SQL, embeddings, RAG, agentes, OWASP) se detallan allá y aquí se enlazan.

---

## 🧩 Cómo se conecta con la arquitectura

```
Documentos (políticas/fraude, con metadata por fecha/producto/país)
        │
        ▼
   Amazon S3 ──► Bedrock Knowledge Base ──► Vector store (OpenSearch Serverless / S3 Vectors)
                        │  (Titan Embeddings V2)
                        ▼
          Retrieve / RetrieveAndGenerate / Converse (boto3)
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
   Bedrock Guardrails   Modelo (Claude)   Citas + lógica de rechazo
        │               │
        ▼               ▼
   FastAPI ──► API Gateway ──► Lambda ──► (CloudWatch: logs, métricas, costo)
        │
        ▼
   Evaluación (retrieval + generación) · IaC (CDK/Terraform) · CI/CD (eval-gates)
        │
        ▼
   🔁 Portabilidad a GCP (Bedrock↔Vertex, KB↔RAG Engine, Guardrails↔Model Armor)
```

**Orden de estudio recomendado:** Capa 0 → 8 (coincide con el orden de los manuales).
**Tiempo total aproximado:** ~4–5 semanas a 8 h/día construyendo mientras lees.

---

# Capa 0 — Fundamentos y entorno AWS

## 0.1 Cuenta AWS, IAM Identity Center, regiones y Budgets
**🧠 Idea central:** en AWS la seguridad y el costo se gestionan desde el minuto cero. **IAM Identity Center** (antes SSO) da usuarios/roles sin usar la cuenta raíz; la **región** define dónde viven tus datos y qué modelos Bedrock tienes; **Budgets** te avisa antes de que un OpenSearch olvidado te vacíe la cuenta. Todo cuelga de una cuenta = límite de facturación y aislamiento.
**🎯 Ruta de lectura (~4 h):** *Getting started con AWS* (~45 min) → *IAM Identity Center* (~1.5 h, crea tu usuario admin y deja de usar root) → *Regiones y disponibilidad de modelos Bedrock* (~30 min, elige una región con Claude) → *AWS Budgets* (~45 min, **configúralo ya**).

- 📘 **① Esencial:** [Getting started con AWS](https://docs.aws.amazon.com/accounts/latest/reference/welcome-first-time-user.html) · [IAM Identity Center](https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html) · [AWS Budgets](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html)
- 📘 **② Referencia:** [IAM — conceptos](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html) · [Regiones y Zonas](https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-regions.html)
- 📘 **③ Avanzada:** [Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) · [Organizations (multi-cuenta)](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_introduction.html)
- 📚 *AWS Certified Cloud Practitioner Study Guide* — Ben Piper & David Clinton · *AWS Security* — Dylan Shields
- 🔀 **Variantes:** 🔁 GCP = proyecto + IAM + Budgets (ver [GCP 0.1](../gcp-fraudshield/mapa-documentacion.md)). ¿cuenta única vs Organizations? ¿región por costo, latencia o disponibilidad de modelos?

## 0.2 CloudShell / AWS CLI / boto3
**🧠 Idea central:** tres formas de hablar con AWS sin salir de la consola web: **CloudShell** (terminal en el navegador, sin instalar nada), **AWS CLI** (mismos comandos en tu máquina) y **boto3** (el SDK de Python — con él programas Bedrock). Dominar boto3 es lo que te deja construir el RAG "a mano".
**🎯 Ruta de lectura (~3 h):** *CloudShell* (~30 min, ábrelo) → *AWS CLI configure* (~45 min) → *boto3 quickstart* + *credentials* (~1.5 h, el patrón `client('bedrock-runtime')` que usarás todo el proyecto).

- 📘 **① Esencial:** [AWS CloudShell](https://docs.aws.amazon.com/cloudshell/latest/userguide/welcome.html) · [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html) · [boto3 quickstart](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/quickstart.html)
- 📘 **② Referencia:** [boto3 — credentials](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/credentials.html) · [boto3 `bedrock-runtime`](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/bedrock-runtime.html) · [boto3 `bedrock-agent-runtime`](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/bedrock-agent-runtime.html)
- 🔀 **Variantes:** 🔁 GCP = Cloud Shell + gcloud + SDKs de Python. ¿CLI vs SDK vs consola para cada tarea?

## 0.3 Amazon Bedrock (plataforma y acceso a modelos)
**🧠 Idea central:** Bedrock es el "catálogo gestionado de modelos" de AWS: accedes a modelos de Anthropic (Claude), Amazon (Titan/Nova), Meta, etc. por una **misma API**, sin servidores. Primero hay que **habilitar el acceso** a cada modelo (Model access) en tu región. Es la base de todas las capas siguientes.
**🎯 Ruta de lectura (~2 h):** *What is Amazon Bedrock* (~45 min) → *Model access* (~30 min, habilita Claude y Titan) → *Supported foundation models* (~45 min, para saber qué IDs tienes).

- 📘 **① Esencial:** [¿Qué es Amazon Bedrock?](https://docs.aws.amazon.com/bedrock/latest/userguide/what-is-bedrock.html) · [Model access](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html)
- 📘 **② Referencia:** [Modelos soportados](https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html) · [Model IDs](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids-arns.html) · [Modelos de Anthropic Claude](https://docs.aws.amazon.com/bedrock/latest/userguide/model-parameters-claude.html)
- 📚 *Generative AI on AWS* — Chris Fregly, Antje Barth & Shelbee Eigenbrode (O'Reilly, **el** libro AWS-GenAI)
- 🔀 **Variantes:** 🔁 GCP = Vertex AI / Gemini. ¿Claude vs Nova vs modelo abierto por costo/capacidad? on-demand vs provisioned throughput.

---

# Capa 1 — RAG desde cero (entender antes de gestionar)

## 1.1 RAG a mano en Python (chunking, embeddings, similitud, citas)
**🧠 Idea central:** antes de usar el RAG gestionado, lo construyes con las manos para *entenderlo por debajo*: partir documentos en **chunks**, convertirlos en **embeddings** (Titan), guardarlos (un simple array NumPy), buscar los top-k por **similitud coseno**, meterlos en el prompt y pedir a Claude una **respuesta con citas**. Así, cuando el gestionado falle, sabes *qué* falló.
**🎯 Ruta de lectura (~2 días):** *Titan Text Embeddings* (~1 h) → *InvokeModel / Converse* para generar (~2 h) → concepto de chunking/overlap y similitud (lee el cap. de embeddings de *Hands-On LLMs*, ~3 h) → construye el pipeline mínimo y mide cómo cambia con chunk size/overlap.

- 📘 **① Esencial:** [Titan Text Embeddings](https://docs.aws.amazon.com/bedrock/latest/userguide/titan-embedding-models.html) · [Inference con Converse](https://docs.aws.amazon.com/bedrock/latest/userguide/conversation-inference.html) · [InvokeModel](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_InvokeModel.html)
- 📚 *Hands-On Large Language Models* — Jay Alammar & Maarten Grootendorst · *AI Engineering* — Chip Huyen (RAG desde los fundamentos)
- 📄 **Paper:** *[Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks](https://arxiv.org/abs/2005.11401)* — Lewis et al. (2020, el paper fundacional)
- 🔀 **Variantes:** chunk size grande vs pequeño (contexto vs precisión); overlap sí/no; similitud coseno vs dot product; búsqueda **semántica vs keyword vs híbrida**. Ver también [GCP 5.1–5.2](../gcp-fraudshield/mapa-documentacion.md).

---

# Capa 2 — Bedrock Knowledge Bases + vector store

## 2.1 Amazon S3
**🧠 Idea central:** el almacén de objetos donde viven los documentos fuente (con su **metadata**: fecha, producto, país — clave para filtrar luego). Es la fuente de verdad que la Knowledge Base ingiere.
**🎯 Ruta de lectura (~1–2 h):** *S3 getting started* (~45 min, crea un bucket y sube docs) → *estructura de objetos y metadata* (~45 min).

- 📘 **① Esencial:** [Amazon S3 — Get started](https://docs.aws.amazon.com/AmazonS3/latest/userguide/GetStartedWithS3.html)
- 📘 **② Referencia:** [Objetos y metadata](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingMetadata.html) · [Clases de almacenamiento](https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-class-intro.html)
- 🔀 **Variantes:** 🔁 GCP = Cloud Storage (ver [GCP 1.1](../gcp-fraudshield/mapa-documentacion.md)). ¿estructura de prefijos vs metadata para el filtrado posterior?

## 2.2 Bedrock Knowledge Bases (RAG gestionado)
**🧠 Idea central:** la KB automatiza todo el pipeline RAG: ingiere de S3, hace chunking, genera embeddings, los indexa en un vector store y sirve `Retrieve`. Desde 2026 hay dos sabores: **Managed Knowledge Base** (AWS gestiona hasta el vector store, con retrieval agéntico multi-hop) y **Customer-managed** (tú traes y controlas el vector store). Es el "RAG en modo fácil" frente al de Capa 1.
**🎯 Ruta de lectura (~1 día):** *How KB works* (~1 h, el modelo mental) → *Create a knowledge base* (~2 h, créala de verdad sobre tu S3) → *Managed vs customer-managed* (~1 h, decide cuál) → *Supported regions/models* como referencia.

- 📘 **① Esencial:** [KB overview](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base.html) · [Cómo funciona](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-how-it-works.html) · [Crear una KB](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-create.html)
- 📘 **② Referencia:** [Managed KB (GA 2026)](https://aws.amazon.com/bedrock/knowledge-bases/) · [Modelos y regiones soportadas](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-supported.html) · [Prerrequisitos de datos](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-ds.html)
- 📘 **③ Avanzada:** [RAG en AWS Prescriptive Guidance](https://docs.aws.amazon.com/prescriptive-guidance/latest/retrieval-augmented-generation-options/rag-fully-managed-bedrock.html)
- 📚 *Generative AI on AWS* — Fregly, Barth & Eigenbrode
- 🔀 **Variantes:** **RAG a mano (Capa 1) vs gestionado (KB)**; Managed vs Customer-managed KB; 🔁 GCP = **Vertex AI RAG Engine** (ver [GCP 5.2](../gcp-fraudshield/mapa-documentacion.md)).

## 2.3 Vector store: OpenSearch Serverless vs S3 Vectors
**🧠 Idea central:** dónde viven los embeddings para búsqueda por vecindad. **OpenSearch Serverless** = alto rendimiento, baja latencia (pero costo mínimo por hora — **apágalo**). **S3 Vectors** (nuevo, GA 2026) = vectores nativos en S3, hasta ~90% más barato, ideal para grandes volúmenes con consultas menos frecuentes. Se pueden combinar por niveles (S3 Vectors frío → OpenSearch caliente).
**🎯 Ruta de lectura (~4–6 h):** *OpenSearch Serverless como vector DB* (~1.5 h) → *S3 Vectors overview + getting started* (~2 h, la opción barata) → *S3 Vectors con Bedrock KB* (~1 h, cómo enchufarlo).

- 📘 **① Esencial:** [OpenSearch Serverless vector database](https://aws.amazon.com/opensearch-service/serverless-vector-database/) · [Amazon S3 Vectors](https://aws.amazon.com/s3/features/vectors/)
- 📘 **② Referencia:** [S3 Vectors — getting started](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-vectors-getting-started.html) · [S3 Vectors con Bedrock KB](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-vectors-bedrock-kb.html) · [Prerrequisitos de vector store](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-setup.html)
- 📘 **③ Avanzada:** [S3 Vectors + OpenSearch por niveles](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-vectors-opensearch.html)
- 🔀 **Variantes:** **OpenSearch Serverless (rápido/caro) vs S3 Vectors (barato/escala) vs pgvector**; 🔁 GCP = **Vertex Vector Search 2.0** (ver [GCP 5.1](../gcp-fraudshield/mapa-documentacion.md)). ¿HNSW params? ¿cuándo por niveles?

## 2.4 Titan Text Embeddings
**🧠 Idea central:** el modelo que convierte texto en vectores dentro de Bedrock. **Titan Text Embeddings V2** (`amazon.titan-embed-text-v2:0`) genera 1024 dimensiones y acepta hasta 8k tokens. La dimensión y el modelo deben ser **consistentes** entre indexado y consulta.
**🎯 Ruta de lectura (~2 h):** *Titan Embeddings* (~1 h) → invócalo por boto3 y mira el vector (~1 h).

- 📘 **① Esencial:** [Titan Text Embeddings](https://docs.aws.amazon.com/bedrock/latest/userguide/titan-embedding-models.html) · [Overview de modelos Titan](https://docs.aws.amazon.com/bedrock/latest/userguide/titan-models.html)
- 🔀 **Variantes:** Titan V2 vs Cohere Embed vs modelo abierto; dimensión 256/512/1024 (costo vs calidad); 🔁 GCP = text-embeddings de Vertex.

---

# Capa 3 — Retrieve / Generate (boto3)

## 3.1 Retrieve, RetrieveAndGenerate y Converse
**🧠 Idea central:** dos niveles de control. `RetrieveAndGenerate` = una llamada, AWS recupera **y** genera con citas (fácil). `Retrieve` + `Converse` = tú recuperas, tú decides el prompt y el modelo (control total: filtros por metadata, lógica de rechazo, sesiones). La **Converse API** unifica el acceso a todos los modelos con una sola interfaz.
**🎯 Ruta de lectura (~1 día):** *RetrieveAndGenerate* (~2 h, la vía gestionada) → *Converse API user guide* (~2 h) → *Retrieve + filtros por metadata* (~2 h, el control fino) → API reference como consulta.

- 📘 **① Esencial:** [Converse API (guía)](https://docs.aws.amazon.com/bedrock/latest/userguide/conversation-inference.html) · [RetrieveAndGenerate (API)](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_agent-runtime_RetrieveAndGenerate.html) · [Retrieve (API)](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_agent-runtime_Retrieve.html)
- 📘 **② Referencia:** [Converse (API ref)](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_Converse.html) · [boto3 `converse`](https://docs.aws.amazon.com/boto3/latest/reference/services/bedrock-runtime/client/converse.html) · [RetrieveAndGenerateStream](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_agent-runtime_RetrieveAndGenerateStream.html)
- 📘 **③ Avanzada:** [Filtros de metadata](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-test-config.html) · [Tool use con Converse](https://docs.aws.amazon.com/bedrock/latest/userguide/tool-use-examples.html)
- 🔀 **Variantes:** `RetrieveAndGenerate` (gestionado) vs `Retrieve`+`Converse` (control); búsqueda híbrida; ¿qué responder cuando no hay evidencia? (lógica de rechazo/grounding).

---

# Capa 4 — Guardrails + seguridad (el diferenciador)

## 4.1 Amazon Bedrock Guardrails
**🧠 Idea central:** una capa de seguridad **independiente del modelo** que filtra entradas y salidas con 6 tipos de política: *content filters*, *denied topics*, *word filters*, *sensitive info (PII)*, *contextual grounding* (bloquea alucinaciones fuera del contexto) y *prompt-attack detection*. Además, **Automated Reasoning checks** valida respuestas contra reglas de negocio con **lógica formal** (ideal en banca/compliance: verifica *matemáticamente* que una respuesta cumple una política). Con `ApplyGuardrail` puedes aplicarla incluso a modelos fuera de Bedrock.
**🎯 Ruta de lectura (~1–2 días):** *Guardrails overview* + *how it works* (~2 h) → *components* (crea uno con las 6 políticas, ~3 h) → *Automated Reasoning checks concepts* (~2 h, el diferenciador de banca) → *ApplyGuardrail* (~1 h). *Developer's Playbook* de Wilson como libro guía en paralelo.
> 🔒 Este es el módulo que responde con evidencia *"¿has usado Guardrails?"* — era tu punto ciego de entrevistas, así que profundízalo.

- 📘 **① Esencial:** [Bedrock Guardrails](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html) · [Cómo funciona](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails-how.html) · [Crear tu guardrail (componentes)](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails-components.html)
- 📘 **② Referencia:** [Automated Reasoning checks](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails-automated-reasoning-checks.html) · [Conceptos de Automated Reasoning](https://docs.aws.amazon.com/bedrock/latest/userguide/automated-reasoning-checks-concepts.html) · [ApplyGuardrail (API)](https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_ApplyGuardrail.html)
- 📘 **③ Avanzada:** [Desplegar política de Automated Reasoning](https://docs.aws.amazon.com/bedrock/latest/userguide/deploy-automated-reasoning-policy.html) (CI/CD, CloudFormation)
- 📚 *The Developer's Playbook for Large Language Model Security* — Steve Wilson (O'Reilly)
- 🔀 **Variantes:** Guardrails nativo vs **Llama Guard** / **NeMo Guardrails** (ver [GCP 8.2](../gcp-fraudshield/mapa-documentacion.md)); input rails vs output rails; 🔁 GCP = **Model Armor**. Automated Reasoning: solo inglés (US) y sin streaming.

## 4.2 Seguridad en profundidad (IAM mínimo, OWASP LLM, logging)
**🧠 Idea central:** Guardrails no basta solo. Defensa en profundidad = **IAM de menor privilegio** (la Lambda solo puede llamar a *su* KB y modelo), **aislamiento del contexto** (que el documento no pueda inyectar instrucciones), **logging** de todo (auditoría) y el marco **OWASP LLM Top 10** como checklist de amenazas.
**🎯 Ruta de lectura (~4–6 h):** *OWASP LLM Top 10* entero (~2 h, la biblia) → *IAM best practices* + políticas de menor privilegio (~2 h) → *CloudTrail/CloudWatch logging* (~1 h).

- 📘 **① Esencial:** [OWASP Top 10 for LLM Applications](https://genai.owasp.org/llm-top-10/) · [IAM best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- 📘 **② Referencia:** [Políticas IAM para Bedrock](https://docs.aws.amazon.com/bedrock/latest/userguide/security-iam.html) · [CloudTrail](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html)
- 📚 *The Developer's Playbook for LLM Security* — Steve Wilson · *AWS Security* — Dylan Shields
- 📄 **Artículo:** [OWASP — Prompt Injection (LLM01)](https://genai.owasp.org/llmrisk/llm01-prompt-injection/)
- 🔀 **Variantes:** ¿roles vs políticas inline? aislamiento del contexto vs sanitización; 🔁 GCP = IAM + DLP + Model Armor (ver [GCP 8.1–8.2](../gcp-fraudshield/mapa-documentacion.md)).

---

# Capa 5 — Evaluación del RAG

## 5.1 Evaluación (Bedrock Evaluations + RAGAS)
**🧠 Idea central:** "parece que responde bien" no es evaluación. Se construye un **dataset dorado** (preguntas respondibles / no respondibles / ambiguas / adversariales / con filtro de metadata) y se miden **retrieval** (context relevance, coverage, hit rate, MRR) y **generación** (faithfulness/alucinación, correctness, completeness, rechazo) **por separado**. Bedrock Evaluations lo hace con *LLM-as-a-judge*; RAGAS es la alternativa portable y multi-cloud.
**🎯 Ruta de lectura (~1–2 días):** *Bedrock Evaluations overview* (~1 h) → *RAG evaluation (evaluation-kb)* (~2 h, crea un job) → métricas de RAGAS (~2 h, ver [GCP 5.4](../gcp-fraudshield/mapa-documentacion.md)) → diseña tu dataset dorado (~medio día, es el activo más valioso).

- 📘 **① Esencial:** [Bedrock Evaluations](https://docs.aws.amazon.com/bedrock/latest/userguide/evaluation.html) · [Evaluar RAG (KB)](https://docs.aws.amazon.com/bedrock/latest/userguide/evaluation-kb.html) · [RAGAS docs](https://docs.ragas.io/en/stable/)
- 📘 **② Referencia:** [Crear un job de RAG eval](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-evaluation-create.html) · [Reportes y métricas](https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base-evaluation-report.html)
- 📄 **Paper:** *[RAGAS: Automated Evaluation of RAG](https://arxiv.org/abs/2309.15217)* — Es et al.
- 📚 *AI Engineering* — Chip Huyen (capítulo de evaluación)
- 🔀 **Variantes:** **Bedrock Evaluations (nativo) vs RAGAS (portable) vs LLM-judge propio**; evaluar retrieval vs generación por separado; evaluar los **Guardrails** (falsos positivos/negativos); métricas de operación (p50/p95, tokens, costo).

---

# Capa 6 — LangChain sobre Bedrock

## 6.1 langchain-aws (ChatBedrockConverse, retriever de KB, LCEL, LangSmith)
**🧠 Idea central:** reimplementar el **mismo** RAG con un framework, para comparar. `ChatBedrockConverse` (modelo), `BedrockEmbeddings`, `AmazonKnowledgeBasesRetriever` (recuperar de tu KB) y **LCEL** (encadenar todo declarativamente), con **LangSmith** para tracing. La lección no es "LangChain es mejor", sino *cuándo* un framework acelera y *cuándo* añade una capa que oscurece el control de boto3.
**🎯 Ruta de lectura (~1 día):** *AWS integrations (LangChain)* (~1 h) → `ChatBedrockConverse` + `AmazonKnowledgeBasesRetriever` (~2 h) → *LCEL* (~2 h) → *LangSmith tracing* (~1 h). Ver también agentes en [GCP 6.1](../gcp-fraudshield/mapa-documentacion.md).

- 📘 **① Esencial:** [AWS integrations — Docs by LangChain](https://docs.langchain.com/oss/python/integrations/providers/aws) · [`ChatBedrockConverse`](https://reference.langchain.com/python/langchain-aws/chat_models/bedrock_converse/ChatBedrockConverse) · [`AmazonKnowledgeBasesRetriever`](https://reference.langchain.com/python/langchain-community/retrievers/bedrock/AmazonKnowledgeBasesRetriever)
- 📘 **② Referencia:** [langchain-aws (PyPI)](https://pypi.org/project/langchain-aws) · [LangSmith — docs](https://docs.langchain.com/langsmith/home)
- 📚 *AI Engineering* — Chip Huyen
- 🔀 **Variantes:** **boto3 nativo vs LangChain** (control vs velocidad/portabilidad); LCEL vs código imperativo; LangSmith vs Langfuse (tracing).

---

# Capa 7 — Despliegue en producción

## 7.1 API Gateway + Lambda + FastAPI
**🧠 Idea central:** el patrón serverless clásico: **API Gateway** recibe la petición HTTP, **Lambda** ejecuta tu código (llama a la KB/Bedrock) y responde — sin servidores, escala solo, pagas por invocación. FastAPI estructura la app; con *streaming* devuelves tokens según se generan.
**🎯 Ruta de lectura (~2–3 días):** *Lambda getting started* (~3 h, despliega una función) → *API Gateway + Lambda* (~4 h, conéctalos) → *streaming de respuestas* (~2 h) → manejo de errores/timeouts/retries (~2 h).

- 📘 **① Esencial:** [AWS Lambda](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html) · [API Gateway](https://docs.aws.amazon.com/apigateway/latest/developerguide/welcome.html) · [FastAPI](https://fastapi.tiangolo.com/)
- 📘 **② Referencia:** [Lambda + API Gateway tutorial](https://docs.aws.amazon.com/apigateway/latest/developerguide/getting-started-with-lambda-integration.html) · [Streaming en Lambda](https://docs.aws.amazon.com/lambda/latest/dg/configuration-response-streaming.html)
- 📚 *Serverless Architectures on AWS* — Peter Sbarski · *Generative AI on AWS* — Fregly, Barth & Eigenbrode
- 🔀 **Variantes:** Lambda vs ECS/Fargate vs App Runner (según cold start/tamaño); 🔁 GCP = Cloud Run (ver [GCP 7.2](../gcp-fraudshield/mapa-documentacion.md)).

## 7.2 IaC: AWS CDK / Terraform
**🧠 Idea central:** describir la infra en código versionado y reproducible. **CDK** usa lenguajes reales (Python/TS) y sintetiza CloudFormation; **Terraform** es multi-cloud y declarativo. Clave para no dejar recursos caros encendidos y para revisar cambios en PR.
**🎯 Ruta de lectura (~1 día):** elige uno. *CDK getting started* (~4 h, si te gusta Python) **o** *Terraform AWS get started* (~4 h, si quieres multi-cloud) → despliega tu stack de verdad.

- 📘 **① Esencial:** [AWS CDK](https://docs.aws.amazon.com/cdk/v2/guide/home.html) · [Terraform — AWS Get Started](https://developer.hashicorp.com/terraform/tutorials/aws-get-started)
- 📘 **② Referencia:** [CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html) · [Provider aws (Terraform)](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- 📚 *Terraform: Up & Running* — Yevgeniy Brikman
- 🔀 **Variantes:** **CDK (código) vs Terraform (declarativo, multi-cloud) vs CloudFormation (crudo)**; 🔁 GCP = Terraform (ver [GCP 7.4](../gcp-fraudshield/mapa-documentacion.md)).

## 7.3 Observabilidad (CloudWatch)
**🧠 Idea central:** en producción necesitas ver logs, métricas (latencia, errores) y **costo por token**. CloudWatch centraliza logs y alarmas; combinado con el logging de Bedrock, sabes qué pregunta costó cuánto y dónde falló.
**🎯 Ruta de lectura (~3–4 h):** *CloudWatch logs + metrics* (~2 h) → *alarmas* (~1 h) → *model invocation logging de Bedrock* (~1 h).

- 📘 **① Esencial:** [Amazon CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html) · [Bedrock — model invocation logging](https://docs.aws.amazon.com/bedrock/latest/userguide/model-invocation-logging.html)
- 🔀 **Variantes:** CloudWatch vs Langfuse/LangSmith (observabilidad de LLM); métricas de sistema vs de calidad; 🔁 GCP = Cloud Monitoring (ver [GCP 8.3](../gcp-fraudshield/mapa-documentacion.md)).

## 7.4 CI/CD con eval-gates (GitHub Actions + OIDC)
**🧠 Idea central:** automatizar el despliegue con una **puerta de calidad**: el pipeline corre la evaluación (Bedrock Eval/RAGAS) y **bloquea el deploy si la calidad del RAG cae**. Autenticar con **OIDC** (sin claves estáticas en GitHub) es la práctica segura.
**🎯 Ruta de lectura (~1 día):** *GitHub Actions* (~2 h, ver [GCP 7.3](../gcp-fraudshield/mapa-documentacion.md)) → *OIDC con AWS* (~2 h, roles sin secretos) → diseña el eval-gate con umbral.

- 📘 **① Esencial:** [GitHub Actions](https://docs.github.com/en/actions) · [OIDC con AWS](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- 📚 *Practical MLOps* — Noah Gift & Alfredo Deza
- 🔀 **Variantes:** **DevOps vs MLOps vs LLMOps**; eval-gate con umbral; OIDC vs access keys.

---

# Capa 8 — Portabilidad multi-cloud (el puente)

## 8.1 Portar el sistema de AWS a GCP
**🧠 Idea central:** un buen ingeniero razona en *capacidades*, no en productos. El mismo RAG se reconstruye en GCP mapeando cada pieza — y explicar ese mapeo demuestra que entiendes el sistema, no solo un proveedor. Es tu narrativa multi-cloud.
**🎯 Ruta de lectura (~4–6 h):** revisa el overview de cada equivalente GCP (enlaces abajo) y arma la tabla de correspondencias tú mismo; construye un slice mínimo en GCP para probarlo.

**Tabla de portabilidad:**

| AWS | GCP | Ficha GCP |
|---|---|---|
| Amazon S3 | Cloud Storage | [1.1](../gcp-fraudshield/mapa-documentacion.md) |
| Bedrock (Claude/Titan) | Vertex AI / Gemini | [5.3](../gcp-fraudshield/mapa-documentacion.md) |
| Bedrock Knowledge Bases | **Vertex AI RAG Engine** | [5.2](../gcp-fraudshield/mapa-documentacion.md) |
| OpenSearch Serverless / S3 Vectors | **Vertex AI Vector Search 2.0** | [5.1](../gcp-fraudshield/mapa-documentacion.md) |
| Bedrock Guardrails | **Model Armor** | ver abajo |
| Lambda + API Gateway | Cloud Run | [7.2](../gcp-fraudshield/mapa-documentacion.md) |
| CloudWatch | Cloud Monitoring | [8.3](../gcp-fraudshield/mapa-documentacion.md) |
| CDK / CloudFormation | Terraform / Deployment Manager | [7.4](../gcp-fraudshield/mapa-documentacion.md) |

- 📘 **① Esencial:** [Model Armor overview](https://cloud.google.com/model-armor/overview) (equivalente de Guardrails; protege modelos de cualquier nube vía REST) · [Vertex AI RAG Engine](https://cloud.google.com/vertex-ai/generative-ai/docs/rag-engine/rag-overview) · [Vertex AI Vector Search](https://cloud.google.com/vertex-ai/docs/vector-search/overview)
- 📄 **Artículo:** [Cómo Model Armor protege tus apps de IA](https://cloud.google.com/blog/products/identity-security/how-model-armor-can-help-protect-your-ai-apps)
- 🔀 **Variantes:** ¿portar todo vs solo el core? ¿abstraer el proveedor (interfaz) desde el día 1 vs acoplarse y portar después? costo/latencia comparados.

---

# 📚 Estantería base (los 6 libros que cruzan todo el proyecto)

| Libro | Autor(es) | Cubre |
|---|---|---|
| *Generative AI on AWS* | Fregly, Barth & Eigenbrode | Bedrock, KB, despliegue (Capas 0–7) |
| *AI Engineering* | Chip Huyen | RAG, evals, agentes (Capas 1, 5, 6) |
| *The Developer's Playbook for LLM Security* | Steve Wilson | Guardrails y seguridad (Capa 4) |
| *Hands-On Large Language Models* | Alammar & Grootendorst | embeddings y RAG (Capa 1) |
| *Serverless Architectures on AWS* | Peter Sbarski | despliegue (Capa 7) |
| *Designing Data-Intensive Applications* | Martin Kleppmann | sistemas (transversal) |

---

> **Método (recordatorio):** para cada componente → 🧠 entiende la idea central → 🎓 curso corto si hace falta → 📘 doc oficial siguiendo la ruta de lectura → implementación mínima (el manual) → 🔀 variantes (romper y reconstruir) → producción/seguridad/eval → documentación propia. La prueba de dominio no es *"lo hice"*, sino *"puedo justificar por qué elegí cada pieza y cambiarla si el requisito cambia"*.
>
> **Fuentes verificadas jul-2026.** AWS evoluciona rápido: Bedrock Managed Knowledge Base (GA jun-2026), S3 Vectors (GA 2026), Guardrails con Automated Reasoning, Converse API como interfaz unificada, docs de LangChain en docs.langchain.com. Los IDs de modelo (Claude/Titan) cambian — confírmalos en *Model IDs*. Si un enlace cambia, busca el término en el sitio oficial y actualiza esta fecha.
