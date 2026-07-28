# 02 · Briefs técnicos de los gaps (para técnica profunda)

> Objetivo: que puedas **conversar con criterio** cada tecnología aunque no la hayas operado. Cada brief trae: qué es, a qué se parece de lo tuyo, el vocabulario que debes nombrar, el ángulo banca, decisiones/variantes, una frase lista y las preguntas a fondo con respuesta corta.

> ⚠️ Verificado a jul-2026, pero son notas de repaso, no doc oficial. Si tienes tiempo, valida un par de conceptos en la doc de AWS.

---

## 🔥 1. Apache Spark

- **🧠 Idea central:** motor de cómputo **distribuido**. Reparte datos y trabajo entre los nodos de un clúster para procesar volúmenes que no caben en una máquina. Trabajas con **DataFrames** (o RDDs) y **evaluación perezosa**: las *transformaciones* (map, filter, join) no se ejecutan hasta que llega una *acción* (count, write, collect).
- **🔗 A qué se parece de lo tuyo:** pandas/SQL, pero paralelizado. Spark SQL es casi idéntico a lo que haces en BigQuery; la diferencia es que TÚ piensas en la distribución.
- **⚙️ Vocabulario que debes nombrar:** *driver* y *executors*; *particiones*; **shuffle** (el movimiento de datos entre nodos — lo caro, hay que minimizarlo); *lazy evaluation*; *transformaciones vs acciones*; *DataFrame vs RDD*; *catalyst optimizer*; **Structured Streaming** (Spark para tiempo real); *MLlib* (ML distribuido).
- **🏦 Ángulo banca:** procesar millones de transacciones para features de riesgo/fraude a escala; joins masivos entre core bancario y eventos.
- **🔀 Decisiones/variantes:** Spark en **EMR** (clúster gestionado) vs **Glue** (serverless, sin gestionar clúster) vs **Databricks**; Spark vs SQL puro (Athena) para transformaciones pesadas; batch vs Structured Streaming.
- **💬 Frase:** *"Spark es mi vía para ETL distribuido cuando el volumen supera una máquina; el modelo mental de transformaciones perezosas y minimizar shuffles lo tengo del mundo columnar. En AWS lo correría vía Glue para no gestionar clúster."*
- **❓ A fondo:**
  - *¿Qué es un shuffle y por qué importa?* → Redistribución de datos entre particiones (p. ej. en un `groupBy`/`join`); es costoso en red/IO, así que se minimiza con particionado y broadcast joins.
  - *¿Diferencia RDD vs DataFrame?* → DataFrame es tabular y optimizado (Catalyst); RDD es de bajo nivel. Hoy usas DataFrames salvo control fino.

---

## 🧪 2. AWS Glue

- **🧠 Idea central:** **ETL serverless** que corre **Spark por debajo** — no gestionas clúster. Incluye el **Glue Data Catalog** (metastore central: qué tablas/esquemas hay, compartido con Athena y otros) y **crawlers** (descubren esquema automáticamente).
- **🔗 A qué se parece de lo tuyo:** es tu capa de transformación (como dbt) pero como servicio AWS, y el Data Catalog es el "diccionario de datos" central.
- **⚙️ Vocabulario:** *Glue jobs* (PySpark), *Glue Data Catalog*, *crawlers*, *Glue Studio* (visual), *DynamicFrame* (el DataFrame de Glue), *bookmarks* (procesamiento incremental).
- **🏦 Ángulo banca:** catalogar y transformar el data lake del banco (S3) con gobernanza de esquema centralizada.
- **🔀 Decisiones/variantes:** Glue (serverless, ideal para cargas intermitentes) vs EMR (clúster, cargas constantes/control fino); Glue vs dbt (dbt vive en el warehouse; Glue en el lake con Spark).
- **💬 Frase:** *"Glue es Spark serverless + un catálogo central; lo usaría para el ETL del data lake y para que Athena y el resto consuman esquemas gobernados desde el Data Catalog."*
- **❓ A fondo:** *¿Para qué el Data Catalog?* → Metastore único: Athena, Glue y EMR leen el mismo esquema/partición; evita definir tablas por duplicado y es base de gobernanza.

---

## 🔎 3. Amazon Athena

- **🧠 Idea central:** consultas **SQL serverless directo sobre S3** (motor **Trino/Presto**). No cargas datos ni gestionas nada; **pagas por datos escaneados**. Usa el Glue Data Catalog para el esquema.
- **🔗 A qué se parece de lo tuyo:** **es el BigQuery de AWS** — mismísimo modelo de "pago por lo escaneado". Todo lo que sabes de particionar/clusterizar para abaratar aplica igual.
- **⚙️ Vocabulario:** *particiones* (clave para no escanear todo), formatos **columnar Parquet/ORC** (más baratos que CSV/JSON), *partition projection*, *CTAS* (Create Table As Select), integración con Glue Catalog.
- **🏦 Ángulo banca:** análisis ad-hoc y exploración sobre el data lake sin mover datos ni levantar warehouse; auditoría/consultas regulatorias.
- **🔀 Decisiones/variantes:** Athena (ad-hoc, serverless, pago por escaneo) vs **Redshift** (warehouse, cargas constantes, mejor para BI intensivo); Parquet vs CSV; particionar por fecha.
- **💬 Frase:** *"Athena es el equivalente de BigQuery en AWS: SQL serverless sobre S3 pagando por escaneo. La misma disciplina —Parquet y particionar por fecha— es la que abarata las consultas."*
- **❓ A fondo:** *¿Cómo bajas el costo de una query en Athena?* → Parquet columnar + particionado + seleccionar solo columnas necesarias → escaneas menos GB.

---

## 🌊 4. Kinesis / Kafka (streaming)

- **🧠 Idea central:** ingestar y procesar datos **en tiempo real** como un flujo continuo de eventos, en vez de por lotes. **Kafka** = log de eventos distribuido (open source); **Kinesis** = el equivalente **gestionado de AWS**.
- **🔗 A qué se parece de lo tuyo:** tus pipelines son batch (corren cada X). Streaming es el mismo dato, pero procesado **evento a evento, al instante** — imprescindible para fraude en tiempo real.
- **⚙️ Vocabulario:** *topic/stream*, **particiones/shards**, *producers/consumers*, **offset** (posición de lectura), *consumer groups*; **Kinesis Data Streams** (shards, tú consumes) vs **Firehose** (entrega gestionada a S3/Redshift); *ventanas* (tumbling/sliding) para agregaciones; garantías *at-least-once* vs *exactly-once*; *event time vs processing time*.
- **🏦 Ángulo banca:** **detección de fraude en tiempo real** — puntuar una transacción en milisegundos al ocurrir; alertas inmediatas. Este es un caso estrella para banca.
- **🔀 Decisiones/variantes:** Kinesis (gestionado, nativo AWS) vs Kafka/MSK (portable, más control); Data Streams (procesas tú) vs Firehose (solo entrega); batch vs streaming (latencia vs simplicidad); procesar con Lambda vs Spark Structured Streaming vs Flink.
- **💬 Frase:** *"Para scoring de fraude en tiempo real usaría Kinesis Data Streams: la transacción entra como evento, una función lo puntúa contra el modelo y dispara alerta en milisegundos. Kafka/MSK si necesito portabilidad multi-cloud."*
- **❓ A fondo:**
  - *¿Shard/partición?* → Unidad de paralelismo y orden; el orden se garantiza **dentro** de un shard, no entre shards. Se particiona por una clave (p. ej. `account_id`).
  - *¿Batch vs streaming para fraude?* → Batch para features históricas y reentrenar; streaming para decidir en el momento. Suelen convivir (arquitectura *lambda/kappa*).

---

## 🤖 5. Amazon SageMaker (el MLOps nativo de AWS)

- **🧠 Idea central:** la **plataforma ML gestionada** de AWS de punta a punta: entrenamiento, **Model Registry**, endpoints de inferencia, **Pipelines** (orquestar ML), **Feature Store**, **Model Monitor** (drift) y **Clarify** (sesgo + explicabilidad).
- **🔗 A qué se parece de lo tuyo:** **es el Vertex AI de AWS** — lo conoces conceptualmente por el proyecto GCP. Mapeo casi 1:1.
- **⚙️ Vocabulario:** *training jobs*, *Model Registry* (versionar/promover), *endpoints* (real-time vs *batch transform* vs *serverless inference*), *Pipelines*, *Feature Store*, *Model Monitor* (data/model drift), **Clarify** (bias + SHAP/explicabilidad), *Processing jobs*.
- **🏦 Ángulo banca:** gobernanza de modelos (registro, aprobación, auditoría), **explicabilidad con Clarify** (regulación exige justificar decisiones de crédito/fraude), monitoreo de drift.
- **🔀 Decisiones/variantes:** SageMaker (gestionado, integrado AWS) vs **Kubeflow** (portable, K8s) vs **MLflow** (tracking ligero); endpoint real-time vs serverless vs batch; entrenar en SageMaker vs Glue/Spark.
- **💬 Frase:** *"SageMaker es el gemelo de Vertex AI que ya usé: training, Model Registry, serving y monitoreo. Para banca destaco Clarify —explicabilidad y sesgo— y Model Monitor para drift, que son requisitos de gobernanza."*
- **❓ A fondo:** *¿SageMaker vs Bedrock?* → Bedrock = modelos fundacionales gestionados (GenAI/LLM); SageMaker = plataforma para tus **propios** modelos (ML clásico/custom). En banca conviven: SageMaker para scoring de fraude, Bedrock para el copiloto RAG.

---

## ☸️ 6. Kubeflow

- **🧠 Idea central:** plataforma de **MLOps sobre Kubernetes**. Sus **Pipelines (KFP)** definen workflows de ML como contenedores; **KServe** sirve modelos. Es potente y portable, pero **pesado** (necesitas operar K8s).
- **🔗 A qué se parece de lo tuyo:** MLflow (tracking) + Airflow (orquestación), pero nativo Kubernetes y todo-en-uno.
- **⚙️ Vocabulario:** *Kubeflow Pipelines (KFP)*, *components* (pasos contenerizados), *KServe/KFServing* (serving), *Katib* (tuning de hiperparámetros), corre sobre **EKS** en AWS.
- **🏦 Ángulo banca:** cuando el banco ya vive en Kubernetes y quiere MLOps portable/multi-cloud sin atarse a un proveedor.
- **🔀 Decisiones/variantes:** **Kubeflow (portable, K8s, complejo) vs SageMaker (gestionado AWS, menos fricción) vs MLflow (ligero, solo tracking)**. Es el clásico *control/portabilidad vs simplicidad*.
- **💬 Frase:** *"Kubeflow lo elegiría si el banco ya estandarizó en Kubernetes y prioriza portabilidad multi-cloud; asumo más complejidad operativa a cambio. Si no, SageMaker reduce fricción."*
- **❓ A fondo:** *¿Por qué no siempre Kubeflow?* → Overhead de operar K8s; para muchos equipos SageMaker/MLflow dan el 80% del valor con una fracción del costo operativo.

---

## 🧠 7. TensorFlow / PyTorch (deep learning)

- **🧠 Idea central:** frameworks para construir y entrenar redes neuronales. **PyTorch** (grafos dinámicos, favorito en investigación, base de Hugging Face) domina el mundo LLM; **TensorFlow** (Keras, TF Serving) fuerte en producción clásica.
- **🔗 A qué se parece de lo tuyo:** **ya rozas PyTorch** — tu fine-tuning con PEFT/LoRA (TRL, bitsandbytes) corre sobre PyTorch. Y tu ML tabular (XGBoost) resuelve lo que rara vez necesita deep learning.
- **⚙️ Vocabulario:** *tensores*, *autograd* (diferenciación automática), *training loop* (forward → loss → backward → step), *optimizer* (Adam), *GPU/CUDA*, *DataLoader*; en HF: `transformers`, `Trainer`.
- **🏦 Ángulo banca:** honestamente, en banca tabular **XGBoost suele ganar**; deep learning entra vía NLP/LLMs (tu terreno RAG) o secuencias. Sé honesto: *"para fraude tabular prefiero gradient boosting; PyTorch entra por el lado LLM"*.
- **🔀 Decisiones/variantes:** PyTorch vs TensorFlow (hoy PyTorch para LLM/research; TF si hay legado); deep learning vs **XGBoost** para tabular (casi siempre XGBoost).
- **💬 Frase:** *"Uso PyTorch a través de Hugging Face para fine-tuning de LLMs (LoRA/QLoRA). Para datos tabulares de fraude, sin embargo, defiendo XGBoost sobre deep learning: mejor rendimiento y explicabilidad."*
- **❓ A fondo:** *¿Cuándo deep learning sobre XGBoost?* → Con texto/imágenes/secuencias o relaciones muy no lineales y muchos datos; para tabular estructurado, boosting suele ser mejor y más interpretable.

---

## 🔀 8. Prefect (bonus, rápido)

- **🧠 Idea central:** orquestador moderno, alternativa a Airflow; más **pythónico** y dinámico (flujos como funciones decoradas).
- **🔗 A qué se parece de lo tuyo:** Airflow (que ya manejas) — mismo propósito, sintaxis distinta.
- **💬 Frase:** *"Domino Airflow —DAGs, idempotencia, reintentos—; Prefect es el mismo concepto con un modelo más pythónico y dinámico, la curva sería corta."*

---

## 🧭 Resumen mental (una tabla para memorizar)

| Concepto | Herramienta AWS | Tu equivalente conocido |
|---|---|---|
| ETL distribuido | Glue (Spark) | dbt + Spark |
| SQL serverless sobre lake | Athena | BigQuery |
| Streaming | Kinesis / MSK (Kafka) | (nuevo — batch → tiempo real) |
| Plataforma ML | SageMaker | Vertex AI |
| MLOps en K8s | Kubeflow sobre EKS | MLflow + Airflow |
| GenAI / LLM gestionado | Bedrock | Vertex AI / Gemini |
| Guardrails | Bedrock Guardrails | (lo tienes ✅) |
| IaC | CloudFormation / CDK / Terraform | Terraform (lo tienes ✅) |

> Si memorizas esta tabla, cualquier pregunta "¿sabes X?" la respondes con *"sí, es el equivalente de Y que ya trabajé, y funciona así…"*.
