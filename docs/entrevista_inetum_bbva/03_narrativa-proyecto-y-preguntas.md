# 03 · Narrativa del proyecto + banco de preguntas

> Cómo contar tu proyecto AWS con autoridad y responder las preguntas técnicas más probables. Practica en voz alta.

---

## 🎤 Narrativa del proyecto (90 segundos)

> *"Construí un **copiloto RAG de producción para banca sobre AWS**: un asistente que responde preguntas sobre políticas bancarias y tipologías de fraude citando la fuente. La arquitectura es **S3 → Bedrock Knowledge Base → vector store (OpenSearch Serverless / S3 Vectors) con Titan Embeddings → Retrieve/Converse con Claude**, expuesto como **API serverless (Lambda + API Gateway)**.*
>
> *Lo llevé de cero a producción en capas: primero **RAG a mano en Python** para entender el mecanismo, luego el gestionado con Bedrock. Le puse foco en tres cosas que en banca son críticas: **seguridad y gobernanza** con Bedrock Guardrails —filtros de contenido, PII, grounding contra alucinaciones y detección de prompt injection—; **evaluación rigurosa** separando calidad de recuperación y de generación con un dataset dorado y RAGAS; y **producción real** con IaC, CI/CD con eval-gates y observabilidad en CloudWatch.*
>
> *La lección que más valoro: no es 'hacer que funcione', es **poder justificar cada decisión** —por qué OpenSearch vs S3 Vectors, por qué boto3 vs LangChain— y cambiarla si el requisito cambia."*

**3 soundbites de reserva:**
- *"Implementé el mismo RAG en boto3 nativo y en LangChain para comparar control vs velocidad."*
- *"Guardrails no es una pestaña: monté las 6 políticas como defensa en profundidad."*
- *"Evalúo retrieval y generación por separado; sin eval no hay eval-gate en CI."*

---

## 🔒 La historia de Guardrails (para NO volver a quedar en frío)

**Bedrock Guardrails — las 6 políticas (memorízalas):**
1. **Content filters** — bloquea contenido dañino (odio, violencia, etc.) por niveles.
2. **Denied topics** — temas prohibidos que defines (p. ej. "no dar asesoría de inversión").
3. **Word filters** — palabras/frases vetadas (lenguaje, competidores).
4. **Sensitive information (PII)** — detecta y enmascara/bloquea datos personales (tarjetas, nombres).
5. **Contextual grounding** — bloquea respuestas **no fundamentadas** en el contexto recuperado → anti-alucinación. Clave en banca.
6. **Prompt attack detection** — detecta **prompt injection / jailbreak**.

**Plus (diferenciador):** **Automated Reasoning checks** — valida respuestas contra reglas de negocio con **lógica formal** (verifica *matemáticamente* el cumplimiento de una política). Ideal para banca/compliance. Y **`ApplyGuardrail`** permite aplicar la barrera incluso a modelos fuera de Bedrock.

**Defensa en profundidad (Guardrails no basta solo):** + IAM de mínimo privilegio + aislamiento del contexto (que un documento no inyecte instrucciones) + logging/auditoría + el marco **OWASP LLM Top 10**.

> Si preguntan *"¿has usado Guardrails?"* → *"Sí, como módulo completo: las 6 políticas más Automated Reasoning para validar reglas de negocio con lógica formal, y ApplyGuardrail para cubrir modelos externos. Y siempre como parte de una defensa en profundidad con IAM, aislamiento de contexto y logging."*

---

## 💬 Banco de preguntas (técnica profunda)

### RAG y GenAI
- **¿Cómo funciona tu RAG por debajo?** → Chunking del documento → embeddings (Titan) → indexado en vector store → por consulta: embedding de la pregunta → top-k por similitud → contexto + pregunta al LLM → respuesta **con citas**. Controlo chunk size/overlap y la estrategia de búsqueda.
- **¿Qué haces cuando el modelo no encuentra evidencia?** → Grounding + abstención: Guardrails (contextual grounding) bloquea respuestas no fundamentadas y el prompt instruye a decir "no tengo información" en vez de alucinar.
- **¿Semántica vs keyword vs híbrida?** → Híbrida (denso + BM25) suele ganar: la densa capta significado, la keyword captura términos exactos (números de póliza, códigos). Re-ranking encima mejora la precisión final.
- **¿Cómo mejoras un RAG que recupera mal?** → Primero *diagnostico* si el fallo es de retrieval o de generación (por eso evalúo por separado). Si es retrieval: chunking, embeddings mejores, híbrida, re-ranking. Si es generación: prompt, modelo, grounding.

### Evaluación (uno de tus diferenciadores)
- **¿Cómo evalúas un RAG?** → Dataset dorado (respondibles / no respondibles / ambiguas / adversariales / con filtro de metadata). Métricas **retrieval** (context precision/recall, hit rate, MRR) vs **generación** (faithfulness/alucinación, correctness, relevancia, rechazo). Con Bedrock Evaluations (LLM-as-judge) o RAGAS (portable).
- **¿Cómo metes eval en CI/CD?** → Un **eval-gate**: el pipeline corre la evaluación y **bloquea el deploy** si la métrica cae de un umbral. Así ningún cambio degrada la calidad en silencio.

### MLOps / LLMOps / gobernanza (peso alto en banca)
- **¿DevOps vs MLOps vs LLMOps?** → DevOps: código. MLOps: + datos y modelo (versionado, drift, reentrenamiento). LLMOps: + evaluación de calidad, prompts, guardrails, costo por token y observabilidad de la *generación*, no solo del sistema.
- **¿Cómo gobiernas modelos en banca?** → Registro y versionado (SageMaker Model Registry/MLflow), aprobación y auditoría, **explicabilidad** (SHAP / SageMaker Clarify), monitoreo de **drift** (Model Monitor/Evidently), trazabilidad de datos (lineage) y control de acceso (IAM/KMS).
- **¿Cumplimiento regulatorio con LLMs?** → PII (DLP + PII filter de Guardrails), grounding para no inventar, logging/auditoría de cada consulta, human-in-the-loop para decisiones sensibles, y residencia de datos (región).

### Datos a escala y streaming
- **¿Cómo procesas millones de transacciones?** → Batch: Spark (vía Glue) para ETL distribuido + Athena para ad-hoc, Parquet + particionado por fecha para costo. Streaming: Kinesis para scoring en tiempo real.
- **¿Fraude en tiempo real?** → Kinesis Data Streams: la transacción entra como evento, se puntúa contra el modelo (endpoint SageMaker o Lambda) en milisegundos y dispara alerta. Features históricas por batch, decisión por streaming (arquitectura lambda/kappa).

### Arquitectura y costos
- **Diséñame una plataforma de IA para el banco en AWS.** → Dibuja el diagrama de [01](./01_requisitos-evidencia-y-gaps.md): fuentes → S3/Glue/Athena (batch) + Kinesis (streaming) → SageMaker (ML) + Bedrock/Guardrails (GenAI) → API serverless → todo bajo MLOps/LLMOps y gobernanza (IAM/KMS/audit).
- **¿Cómo optimizas costos?** → Bedrock: modelo Flash vs Pro según necesidad, caché. Vector store: S3 Vectors (barato) vs OpenSearch (rápido) según frecuencia. Athena: Parquet + particionado. Serverless (Lambda/Cloud Run) para pagar por uso. Budgets y alertas.

### Senior / comportamiento
- **Una decisión de arquitectura difícil y por qué.** → Usa un ADR real: *"ChromaDB vs Vertex/OpenSearch para el vector store: en prototipo elegí el simple con la interfaz abstraída para migrar sin reescribir el pipeline. Prioricé velocidad de iteración; asumí deuda de 'no producción' mitigada por el desacoplamiento."*
- **Un error del que aprendiste.** → El de la **fuga de datos** (modelo daba AUC 0.99 porque incluí features que solo existen después de conocer el fraude). Lección: por cada feature, *"¿existiría en el momento de predecir?"*.

---

## ❓ Preguntas que TÚ haces (muestran nivel senior)

- *"¿En qué punto está BBVA en su madurez de MLOps/LLMOps — exploración, primeros modelos en producción, o plataforma consolidada?"*
- *"¿El foco inicial del rol es más GenAI/RAG o plataforma de datos y ML clásico a escala?"*
- *"¿Cómo gestionan hoy la gobernanza y el cumplimiento regulatorio de los modelos?"*
- *"¿Qué stack de streaming usan — Kinesis, Kafka/MSK — y para qué casos en tiempo real?"*
- *"¿Cómo se reparte el trabajo entre el equipo de Inetum y los equipos internos del banco?"*

---

## ⚡ Anti-pánico (si no sabes algo)

1. **No inventes.** *"No lo he usado en producción, pero conozco el concepto: es el equivalente de [X] que sí trabajé…"*.
2. **Reconduce a tu fuerte:** RAG, Guardrails, evaluación, explicabilidad.
3. **Razona en voz alta:** un senior demuestra *cómo piensa*, no que se sabe todo de memoria.
4. **Cierra con trade-off:** toda elección tiene un costo; nómbralo.
