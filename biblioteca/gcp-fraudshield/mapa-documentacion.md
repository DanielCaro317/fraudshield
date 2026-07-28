# 🗺️ Mapa de documentación — GCP FraudShield

> **Proyecto:** plataforma cloud-native de detección de fraude bancario (datos + ML + RAG + agentes) en Google Cloud.
> **Cómo leerlo:** este mapa es la capa de *"qué estudiar, en qué orden y por qué"* que envuelve los [manuales](../../gcp-fraudshield/manuales/) (la *implementación*). Lee la ficha **antes** de construir el manual, y vuelve a ella para romper y reconstruir con una variante.
> **Verificado:** jul-2026.

### Anatomía de cada ficha
- **🧠 Idea central** — el modelo mental en 2-4 frases: qué es *de verdad* y por qué está en el proyecto. Si solo lees esto, ya entiendes el rol de la pieza.
- **🎯 Ruta de lectura** — por dónde empezar, en qué orden, qué leer a fondo y qué saltar, con **⏱️ tiempo estimado** de estudio (para ~8 h/día).
- **📘 Documentación oficial** — **①** esencial (leer sí o sí) · **②** referencia (consultar al implementar) · **③** avanzada (producción/optimización).
- **📚 Libros** (nombre + autor) · **📄 artículos/papers** · **🎓 curso** (solo si la doc no basta) · **🔀 decisiones y variantes** (el "rompe y reconstruye").

> ⏱️ Los tiempos son de *estudio para dominar lo relevante al proyecto*, no de leer la doc entera. Son orientativos.

---

## 🧩 Cómo se conecta con la arquitectura

```
Fuentes (PaySim/Kaggle + CFPB)
      │
      ▼
 Cloud Storage (Data Lake)  ──►  BigQuery (Data Warehouse)
      │                              │
      │                              ▼
      │                        dbt (ELT, features)   ◄── orquesta ── Airflow (Composer 3)
      │                              │
      │            ┌─────────────────┴─────────────────┐
      │            ▼                                    ▼
      │   ML detección de fraude              RAG consultas semánticas
      │   (BigQuery ML / Vertex AI /          (embeddings + vector search
      │    scikit-learn / XGBoost)             sobre quejas)  +  RAGAS / Langfuse
      │            │                                    │
      │            └──────────────┬─────────────────────┘
      │                           ▼
      │              Agente Investigador (LangGraph)
      │                           │
      ▼                           ▼
 Seguridad / IAM / DLP     FastAPI + Docker ──► Cloud Run (API) ──► React (dashboard)
 Observabilidad / drift          │
                          CI/CD (GitHub Actions + eval-gates) · Terraform (IaC)
```

**Orden de estudio recomendado:** Capa 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 (coincide con el orden de los manuales).
**Tiempo total aproximado del recorrido:** ~6–8 semanas a 8 h/día si construyes mientras lees (que es el punto).

---

# Capa 0 — Fundamentos y entorno

## 0.1 Google Cloud Platform (Cloud Shell, gcloud, IAM, billing)
**🧠 Idea central:** GCP es un conjunto de servicios que alquilas por API. Todo cuelga de un *proyecto* (unidad de facturación y permisos); **IAM** decide *quién* (identidad) puede *hacer qué* (rol) *sobre qué* (recurso). Cloud Shell es una VM Linux gratis con `gcloud` ya instalado: tu panel de control sin instalar nada.
**🎯 Ruta de lectura (~3–4 h):** empieza por *Get started* (~45 min) para el modelo proyecto/facturación → *Cloud Shell* (~30 min, ábrelo y úsalo) → *IAM overview* (~1 h, el concepto identidad→rol→recurso es lo que más se pregunta) → hojea la referencia de `gcloud` sin memorizar. Salta el Architecture Framework por ahora (vuelve en Capa 7-8).

- 📘 **① Esencial:** [Get started con GCP](https://cloud.google.com/docs/get-started) · [Cloud Shell](https://cloud.google.com/shell/docs) · [gcloud CLI overview](https://cloud.google.com/sdk/gcloud)
- 📘 **② Referencia:** [Referencia de comandos gcloud](https://cloud.google.com/sdk/gcloud/reference) · [Jerarquía de recursos](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy)
- 📘 **③ Avanzada:** [IAM overview](https://cloud.google.com/iam/docs/overview) · [Presupuestos y alertas](https://cloud.google.com/billing/docs/how-to/budgets) · [Architecture Framework](https://cloud.google.com/architecture/framework)
- 📚 *Google Cloud Certified Associate Cloud Engineer Study Guide* — Dan Sullivan · *Site Reliability Engineering* — Beyer, Jones, Petoff, Murphy (Google, gratis online)
- 🔀 **Variantes:** ¿proyecto único vs carpeta/organización? ¿roles predefinidos vs personalizados? ¿cuándo una service account en vez de tu usuario?

## 0.2 Python
**🧠 Idea central:** el lenguaje pegamento del proyecto (ingesta, ML, RAG, agentes, API). Lo que separa a un junior de un senior aquí no es la sintaxis, sino los entornos aislados (`venv`), el tipado y escribir código que otro pueda mantener.
**🎯 Ruta de lectura (~refuerzo, no desde cero):** ya lo usas, así que salta el tutorial básico. Ve directo a *venv* (~30 min, higiene de entornos) y *typing* (~1 h). Usa *Effective Python* como checklist de buenas prácticas mientras codeas, no de corrido.

- 📘 **① Esencial:** [Tutorial oficial](https://docs.python.org/3/tutorial/) · [Language Reference](https://docs.python.org/3/reference/)
- 📘 **② Referencia:** [Standard Library](https://docs.python.org/3/library/) · [venv](https://docs.python.org/3/library/venv.html) · [typing](https://docs.python.org/3/library/typing.html)
- 📚 *Python for Data Analysis* — Wes McKinney (creador de pandas) · *Fluent Python* — Luciano Ramalho (avanzado) · *Effective Python* — Brett Slatkin
- 🔀 **Variantes:** ¿pandas vs Polars para volumen? ¿scripts vs paquete instalable? ¿tipado con mypy sí o no?

## 0.3 SQL
**🧠 Idea central:** SQL es *declarativo* — describes el resultado, el motor decide cómo. En un DW columnar como BigQuery, pensar en conjuntos (no en bucles) y saber *qué* datos escaneas es lo que separa una consulta de 0.01 USD de una de 5 USD. Es el idioma de toda la Capa 1-2.
**🎯 Ruta de lectura (~4–6 h):** *Introducción a GoogleSQL* (~1 h) → practica SELECT/JOIN/GROUP BY en la consola con datos reales → *window functions* (el tema que más distingue, ~2 h) → hojea funciones/operadores como referencia. *Learning SQL* si necesitas base; *SQL for Data Analysis* para patrones analíticos reales.

- 📘 **① Esencial:** [Introducción a GoogleSQL](https://cloud.google.com/bigquery/docs/introduction-sql)
- 📘 **② Referencia:** [Sintaxis de consultas](https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax) · [Funciones y operadores](https://cloud.google.com/bigquery/docs/reference/standard-sql/functions-and-operators)
- 📚 *SQL for Data Analysis* — Cathy Tanimura · *Learning SQL* — Alan Beaulieu · *The Data Warehouse Toolkit* — Ralph Kimball & Margy Ross (modelado dimensional, clásico)
- 🔀 **Variantes:** window functions vs subconsultas; CTEs vs tablas temporales; ¿cuándo desnormalizar en un DW columnar?

---

# Capa 1 — Ingesta y Data Lake

## 1.1 Cloud Storage (Data Lake)
**🧠 Idea central:** almacenamiento de *objetos* (archivos) infinitamente escalable. No es un disco ni una base de datos: es una tabla clave→archivo global. Aquí aterriza el dato **crudo** (`raw/`) tal como llega, antes de tocarlo — la zona de aterrizaje del ELT.
**🎯 Ruta de lectura (~1–2 h):** *Overview* (~20 min) → *Crear buckets* + súbete un archivo por consola y por CLI (~40 min) → *clases de almacenamiento* (~20 min, importa por costo) → *lifecycle* solo cuando pienses en costos a largo plazo. Usa `gcloud storage`, **no** `gsutil` (deprecado).

- 📘 **① Esencial:** [Cloud Storage overview](https://cloud.google.com/storage/docs/introduction) · [Crear buckets](https://cloud.google.com/storage/docs/creating-buckets) · [`gcloud storage`](https://cloud.google.com/sdk/gcloud/reference/storage)
- 📘 **② Referencia:** [Clases de almacenamiento](https://cloud.google.com/storage/docs/storage-classes) · [Objetos](https://cloud.google.com/storage/docs/objects)
- 📘 **③ Avanzada:** [Lifecycle Management](https://cloud.google.com/storage/docs/lifecycle) · [Control de acceso](https://cloud.google.com/storage/docs/access-control)
- 📚 *Fundamentals of Data Engineering* — Joe Reis & Matt Housley (almacenamiento y arquitectura de data lakes)
- 🔀 **Variantes:** 🔁 AWS = **S3**. ¿Data Lake plano vs lakehouse (Iceberg/BigLake)? ¿qué clase por costo/latencia?

## 1.2 BigQuery (Data Warehouse)
**🧠 Idea central:** un DW *serverless* y *columnar*: no gestionas servidores y solo pagas por los datos que **escaneas** (no por almacenar ni por tiempo). Separa cómputo de almacenamiento, así que escala a petabytes. Es el cerebro analítico del proyecto: aquí viven `raw`, staging y marts, y hasta puedes entrenar ML sin sacar el dato (Capa 4.4).
**🎯 Ruta de lectura (~4–6 h):** *¿Qué es BigQuery?* (~30 min) → *Cargar datos* desde GCS (~1 h, práctico) → *particionado* y *clustering* (~1.5 h, es lo que abarata y acelera) → *Best practices: costos* (~1 h, **léelo antes de lanzar consultas grandes** o gastarás de más) → `bq` CLI como referencia.

- 📘 **① Esencial:** [¿Qué es BigQuery?](https://cloud.google.com/bigquery/docs/introduction) · [Cargar datos](https://cloud.google.com/bigquery/docs/loading-data) · [Datasets y tablas](https://cloud.google.com/bigquery/docs/datasets-intro)
- 📘 **② Referencia:** [`bq` CLI](https://cloud.google.com/bigquery/docs/bq-command-line-tool) · [Tipos de datos](https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types) · [Tablas particionadas](https://cloud.google.com/bigquery/docs/partitioned-tables) · [Clustering](https://cloud.google.com/bigquery/docs/clustered-tables)
- 📘 **③ Avanzada:** [Controlar costos](https://cloud.google.com/bigquery/docs/best-practices-costs) · [Optimización de consultas](https://cloud.google.com/bigquery/docs/best-practices-performance-overview) · [Editions / slots](https://cloud.google.com/bigquery/docs/editions-intro)
- 📚 *Google BigQuery: The Definitive Guide* — Valliappa Lakshmanan & Jordan Tigani · *Designing Data-Intensive Applications* — Martin Kleppmann (sistemas de datos, imprescindible)
- 🔀 **Variantes:** 🔁 AWS = **Redshift** o **Athena** (SQL serverless sobre S3). ¿Particionar por fecha vs clusterizar? ¿on-demand vs slots?

## 1.3 Fuentes de datos (prospección)
**🧠 Idea central:** un ingeniero de datos *prospecta* fuentes: distingue lo **estructurado** (transacciones — filas/columnas, van a ML) de lo **no estructurado** (narrativas de quejas — texto libre, van a RAG). PaySim es un simulador (dato sintético realista de fraude); CFPB son quejas reales de clientes de banca en EE. UU.
**🎯 Ruta de lectura (~1 h):** hojea la ficha de cada dataset y **descarga una muestra** para mirar columnas y volumen antes de diseñar nada. Lee el paper de PaySim (~30 min) para entender cómo se generó el fraude sintético (útil para no sobre-confiar en él).

- 📘 **① Esencial:** [Kaggle Datasets](https://www.kaggle.com/docs/datasets) (PaySim) · [CFPB Consumer Complaint Database](https://www.consumerfinance.gov/data-research/consumer-complaints/) (quejas)
- 📄 **Artículo:** *PaySim: A financial mobile money simulator for fraud detection* — Lopez-Rojas, Elmir & Axelsson
- 🔀 **Variantes:** estructurado (transacciones) vs no estructurado (quejas → RAG en Capa 5); ¿batch vs streaming (Pub/Sub)?

---

# Capa 2 — Transformación (ELT)

## 2.1 dbt + adaptador BigQuery
**🧠 Idea central:** dbt trae la disciplina del software (control de versiones, tests, modularidad, documentación) al SQL analítico. Tú escribes `SELECT`s; dbt gestiona el orden de dependencias, materializa vistas/tablas y verifica calidad. Es la **"T" del ELT**: convierte `raw` en capas limpias (staging → intermediate → marts) y en las **features de fraude**.
**🎯 Ruta de lectura (~1–2 días):** haz el curso *dbt Fundamentals* (~4 h, es gratis y el tema es muy práctico) → *What is dbt?* + *Conectar BigQuery* (~1 h, configúralo de verdad) → *Models* y *Tests* (~3 h, el núcleo) → *Best practices / project structure* (~1 h, para no armar un espagueti) → *incremental models* solo cuando el volumen lo pida.

- 📘 **① Esencial:** [What is dbt?](https://docs.getdbt.com/docs/introduction) · [Conectar BigQuery](https://docs.getdbt.com/docs/core/connect-data-platform/bigquery-setup) · [🎓 dbt Fundamentals (curso oficial gratis)](https://learn.getdbt.com/)
- 📘 **② Referencia:** [Models](https://docs.getdbt.com/docs/build/models) · [Tests](https://docs.getdbt.com/docs/build/data-tests) · [Sources](https://docs.getdbt.com/docs/build/sources) · [BigQuery configs](https://docs.getdbt.com/reference/resource-configs/bigquery-configs)
- 📘 **③ Avanzada:** [Incremental models](https://docs.getdbt.com/docs/build/incremental-models) · [Best practices](https://docs.getdbt.com/best-practices) · [Exposures & lineage](https://docs.getdbt.com/docs/build/exposures)
- 📚 *Analytics Engineering with SQL and dbt* — Rui Machado & Hélder Russa · *Fundamentals of Data Engineering* — Reis & Housley (marco ELT)
- 📄 **Artículo:** *[The dbt Viewpoint](https://docs.getdbt.com/community/resources/viewpoint)* (manifiesto de analytics engineering)
- 🔀 **Variantes:** ETL vs **ELT**; patrón medallion (bronze/silver/gold); ¿dbt Core (OSS) vs dbt Cloud? ¿tests genéricos vs singulares vs `dbt_expectations`?

---

# Capa 3 — Orquestación

## 3.1 Apache Airflow + Cloud Composer 3
**🧠 Idea central:** Airflow programa y vigila *workflows* como **DAGs** (grafos de tareas sin ciclos): "primero ingesta, luego dbt, luego entrena, y si algo falla reintenta". Su valor no es correr código, sino **fiabilidad**: scheduling, reintentos, alertas e **idempotencia** (poder re-ejecutar sin duplicar). Cloud Composer es Airflow gestionado por Google (potente, pero **caro — apágalo**).
**🎯 Ruta de lectura (~2–3 días):** *Core Concepts* (~2 h: DAG, task, operator, scheduler) → *Tutorial de DAGs* (~3 h, escribe uno de verdad) → *Providers de Google* (~2 h, los operadores de BigQuery/GCS) → *Best practices* + idempotencia (~2 h, lo que se pregunta en entrevista) → Composer 3 solo para la demo gestionada.

- 📘 **① Esencial:** [Airflow — Core Concepts](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/index.html) · [Tutorial de DAGs](https://airflow.apache.org/docs/apache-airflow/stable/tutorial/index.html) · [Cloud Composer overview](https://cloud.google.com/composer/docs/composer-3/composer-overview) *(ahora "Managed Service for Apache Airflow", soporta Airflow 3.1)*
- 📘 **② Referencia:** [Authoring & scheduling](https://airflow.apache.org/docs/apache-airflow/stable/authoring-and-scheduling/index.html) · [Providers de Google](https://airflow.apache.org/docs/apache-airflow-providers-google/stable/index.html) · [Quickstart Composer 3](https://cloud.google.com/composer/docs/composer-3/run-apache-airflow-dag)
- 📘 **③ Avanzada:** [Best practices](https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html) · [Deferrable operators](https://airflow.apache.org/docs/apache-airflow/stable/authoring-and-scheduling/deferring.html) · [Dynamic task mapping](https://airflow.apache.org/docs/apache-airflow/stable/authoring-and-scheduling/dynamic-task-mapping.html)
- 📚 *Data Pipelines with Apache Airflow* — Bas Harenslak & Julian de Ruiter (Manning)
- 🔀 **Variantes:** Airflow vs **Composer** (gestionado, caro); ¿vs alternativas ligeras (Cloud Workflows, Dagster, Prefect)? idempotencia y `catchup`; ¿dbt como `BashOperator` vs Cosmos?

---

# Capa 4 — Machine Learning (detección de fraude)

## 4.1 Fundamentos de ML supervisado (scikit-learn)
**🧠 Idea central:** aprendizaje supervisado = aprender una función `X → y` a partir de ejemplos etiquetados (transacción → fraude/no). scikit-learn estandarizó el flujo `fit`/`predict` y el **Pipeline** (encadenar preprocesado + modelo para que no haya fugas). El 80% del trabajo no es el modelo, sino la validación honesta y las métricas correctas.
**🎯 Ruta de lectura (~1 día):** *Getting started* (~1 h) → *Pipelines* (~1 h, clave para evitar leakage) → *Model evaluation* (~2 h, entiende precision/recall/PR **antes** de mirar accuracy) → *Cross-validation* (~1 h). Usa Géron como libro guía de todo el capítulo.

- 📘 **① Esencial:** [scikit-learn — User Guide](https://scikit-learn.org/stable/user_guide.html) · [Getting started](https://scikit-learn.org/stable/getting_started.html)
- 📘 **② Referencia:** [Pipelines](https://scikit-learn.org/stable/modules/compose.html) · [Métricas](https://scikit-learn.org/stable/modules/model_evaluation.html) · [Cross-validation](https://scikit-learn.org/stable/modules/cross_validation.html)
- 📚 *Hands-On Machine Learning…* — Aurélien Géron (**el** libro) · *An Introduction to Statistical Learning* (ISLP) — James, Witten, Hastie, Tibshirani (gratis) · *The Elements of Statistical Learning* — Hastie, Tibshirani, Friedman (avanzado, gratis)
- 🔀 **Variantes:** ¿modelo lineal interpretable vs árbol potente? train/val/test vs CV; **fuga de datos** (data leakage) — el error #1 en fraude.

## 4.2 XGBoost / Gradient Boosting
**🧠 Idea central:** el boosting entrena árboles en secuencia, cada uno corrigiendo los errores del anterior. Para datos **tabulares** (como transacciones) suele ganarle al deep learning. XGBoost es la implementación de referencia; entender `scale_pos_weight`, `max_depth` y `learning_rate` es el 90% de sacarle provecho en fraude.
**🎯 Ruta de lectura (~4–6 h):** *Get Started* (~30 min) → *Tutoriales* (~2 h) → *Parameter tuning* + `scale_pos_weight` (~2 h, esto es lo que conecta con el desbalance de 4.3) → el paper para el "por qué" (~1 h, opcional pero ilumina).

- 📘 **① Esencial:** [XGBoost — Get Started](https://xgboost.readthedocs.io/en/stable/get_started.html) · [Tutoriales](https://xgboost.readthedocs.io/en/stable/tutorials/index.html)
- 📘 **② Referencia:** [Parámetros](https://xgboost.readthedocs.io/en/stable/parameter.html) · [Python API](https://xgboost.readthedocs.io/en/stable/python/python_api.html) · [Param tuning (`scale_pos_weight`)](https://xgboost.readthedocs.io/en/stable/tutorials/param_tuning.html)
- 📄 **Paper:** *[XGBoost: A Scalable Tree Boosting System](https://arxiv.org/abs/1603.02754)* — Chen & Guestrin (2016)
- 🔀 **Variantes:** XGBoost vs LightGBM vs CatBoost; early stopping; ¿boosting vs random forest para fraude?

## 4.3 Clases desbalanceadas (el corazón del problema de fraude)
**🧠 Idea central:** el fraude es <1% de las transacciones. Un modelo que dice "nunca hay fraude" acierta el 99%… y es inútil. Por eso **accuracy engaña** y mandan la *precision*, el *recall* y la **curva Precision-Recall**. La palanca de negocio es el **umbral**: mover dónde cortas cambia el balance entre molestar a clientes legítimos (falsos positivos) y dejar pasar fraude.
**🎯 Ruta de lectura (~1 día, el más importante del capítulo):** *imbalanced-learn User Guide* (~2 h) → ejemplo *Precision-Recall* de scikit-learn (~1 h) → hojea el **handbook de fraude** (gratis) capítulos de métricas y validación (~2–3 h, es específico de tu problema) → paper SMOTE para el "por qué" del remuestreo.

- 📘 **① Esencial:** [imbalanced-learn — User Guide](https://imbalanced-learn.org/stable/user_guide.html) · [scikit-learn: Precision-Recall](https://scikit-learn.org/stable/auto_examples/model_selection/plot_precision_recall.html)
- 📚 *[Reproducible ML for Credit Card Fraud Detection](https://fraud-detection-handbook.github.io/fraud-detection-handbook/)* — Le Borgne, Siblini, Lebichot & Bontempi (ULB; handbook gratis, **específico de fraude**) · *Imbalanced Learning* — He & Ma
- 📄 **Paper:** *[SMOTE: Synthetic Minority Over-sampling Technique](https://arxiv.org/abs/1106.1813)* — Chawla et al. (2002)
- 🔀 **Variantes:** **AUC-PR vs AUC-ROC** (por qué PR manda); SMOTE vs undersampling vs `class_weight`; ajuste de **umbral** por costo de negocio.

## 4.4 BigQuery ML (baseline en SQL)
**🧠 Idea central:** entrenar un modelo con `CREATE MODEL ... AS SELECT` — ML sin sacar el dato del DW ni escribir Python. No reemplaza a Vertex para casos complejos, pero te da un **baseline honesto en minutos**, y en fraude ya trae detección de anomalías lista.
**🎯 Ruta de lectura (~3–4 h):** *Introducción a BQML* (~45 min) → *Tutorial boosted trees classifier* (~1.5 h, hazlo entero) → `CREATE MODEL` + `ML.PREDICT` como referencia → *anomaly detection* (~45 min, encaja perfecto con fraude).

- 📘 **① Esencial:** [Introducción a BigQuery ML](https://cloud.google.com/bigquery/docs/bqml-introduction) · [Tutorial clasificación boosted trees](https://cloud.google.com/bigquery/docs/boosted-tree-classifier-tutorial)
- 📘 **② Referencia:** [`CREATE MODEL`](https://cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create) · [`CREATE MODEL` boosted trees](https://cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create-boosted-tree) · [`ML.PREDICT`](https://cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-predict)
- 📘 **③ Avanzada:** [Detección de anomalías (fraude)](https://cloud.google.com/bigquery/docs/anomaly-detection-overview) · [Hyperparameter tuning](https://cloud.google.com/bigquery/docs/hp-tuning-overview)
- 🔀 **Variantes:** BQML (baseline SQL) vs **Vertex AI** (control total, Python) vs modelo local; ¿cuándo el baseline ya basta?

## 4.5 Vertex AI (entrenamiento y registro de modelos)
**🧠 Idea central:** la plataforma unificada de ML/IA de Google (rebautizada "Gemini Enterprise Agent Platform"). Cubre el ciclo completo: entrenamiento custom, **Model Registry** (versionar modelos), endpoints (servir), pipelines (automatizar) y monitoreo. Es a donde escalas cuando BQML se queda corto.
**🎯 Ruta de lectura (~1–2 días):** *Introducción a la plataforma* (~1 h) → *Custom training overview* (~2 h) → *Model Registry* (~1 h, el concepto de versionar+promover) → *Predictions/endpoints* (~2 h) → *Pipelines* y *Model Monitoring* cuando entres a MLOps (Capa 7-8).

- 📘 **① Esencial:** [Vertex AI — Introducción](https://cloud.google.com/vertex-ai/docs/start/introduction-unified-platform) · [Custom training overview](https://cloud.google.com/vertex-ai/docs/training/overview)
- 📘 **② Referencia:** [Model Registry](https://cloud.google.com/vertex-ai/docs/model-registry/introduction) · [Predictions](https://cloud.google.com/vertex-ai/docs/predictions/overview) · [Pipelines](https://cloud.google.com/vertex-ai/docs/pipelines/introduction)
- 📘 **③ Avanzada:** [Feature Store](https://cloud.google.com/vertex-ai/docs/featurestore) · [Model Monitoring](https://cloud.google.com/vertex-ai/docs/model-monitoring/overview)
- 📚 *Machine Learning Design Patterns* — Lakshmanan, Robinson & Munn (Google) · *Designing Machine Learning Systems* — Chip Huyen
- 🔀 **Variantes:** BQML vs Vertex custom vs AutoML; ¿registrar en Vertex Model Registry vs MLflow (Capa 7)?

## 4.6 Explicabilidad (SHAP)
**🧠 Idea central:** en banca no basta con acertar: hay que **justificar** por qué el modelo marcó una transacción (regulación, auditoría, confianza del analista). SHAP reparte la predicción entre las features usando teoría de juegos (valores de Shapley): "esta transacción es fraude *sobre todo* por el monto y la hora".
**🎯 Ruta de lectura (~2–3 h):** doc de SHAP + los ejemplos de force/summary plot (~1.5 h, muy visual) → capítulo SHAP del *Interpretable ML book* de Molnar (~1 h, gratis, la mejor explicación conceptual).

- 📘 **① Esencial:** [SHAP — documentación](https://shap.readthedocs.io/en/latest/)
- 📚 *[Interpretable Machine Learning](https://christophm.github.io/interpretable-ml-book/)* — Christoph Molnar (gratis online)
- 📄 **Paper:** *[A Unified Approach to Interpreting Model Predictions](https://arxiv.org/abs/1705.07874)* — Lundberg & Lee (2017)
- 🔀 **Variantes:** SHAP vs LIME vs importancia nativa; explicaciones globales vs locales (por transacción).

## 4.7 Fine-tuning local (PEFT / LoRA / QLoRA)
**🧠 Idea central:** afinar un LLM entero es carísimo; **PEFT** congela el modelo y entrena solo unos pocos parámetros nuevos (**LoRA** = matrices de bajo rango; **QLoRA** = LoRA sobre un modelo cuantizado a 4-bit, cabe en tu RTX 4070). La lección de diseño más valiosa no es *cómo* afinar, sino *cuándo*: **RAG vs fine-tuning vs prompting**.
**🎯 Ruta de lectura (~2–3 días):** primero decide con el árbol RAG/fine-tuning/prompting (lee la intro de PEFT, ~1 h) → *conceptual guide: LoRA* (~1 h) → *TRL SFTTrainer* (~2 h, el entrenador) → *quantization/bitsandbytes* (~1 h) → papers LoRA/QLoRA para el fundamento. Ollama para servir el modelo afinado en local.

- 📘 **① Esencial:** [Hugging Face PEFT](https://huggingface.co/docs/peft/index) · [TRL — SFTTrainer](https://huggingface.co/docs/trl/index) · [Ollama](https://github.com/ollama/ollama/tree/main/docs)
- 📘 **② Referencia:** [LoRA en PEFT](https://huggingface.co/docs/peft/conceptual_guides/lora) · [Quantization (bitsandbytes)](https://huggingface.co/docs/transformers/quantization/bitsandbytes)
- 📄 **Papers:** *[LoRA](https://arxiv.org/abs/2106.09685)* — Hu et al. · *[QLoRA](https://arxiv.org/abs/2305.14314)* — Dettmers et al.
- 📚 *Hands-On Large Language Models* — Jay Alammar & Maarten Grootendorst
- 🔀 **Variantes:** **RAG vs fine-tuning vs prompting** (el árbol de decisión clave); full FT vs LoRA vs QLoRA; ¿cuándo afinar aporta sobre RAG?

## 4.8 Metodología: CRISP-DM
**🧠 Idea central:** el ciclo estándar de un proyecto de datos: *comprensión del negocio → de los datos → preparación → modelado → evaluación → despliegue*, iterando. Te obliga a empezar por el **problema de negocio** (¿cuánto cuesta un fraude no detectado?) antes que por el modelo.
**🎯 Ruta de lectura (~1–2 h):** lee la guía original (~1 h) y mapea cada fase a tus manuales. *Data Science for Business* para el marco de decisión.

- 📄 **Artículo:** [CRISP-DM (guía original, IBM)](https://www.ibm.com/docs/en/spss-modeler/saas?topic=dm-crisp-help-overview) · 📚 *Data Science for Business* — Provost & Fawcett
- 🔀 **Variantes:** CRISP-DM vs enfoque Ágil/iterativo; ¿dónde encaja el negocio antifraude en cada fase?

---

# Capa 5 — GenAI y RAG (consultas semánticas sobre quejas)

## 5.1 Embeddings y vector stores
**🧠 Idea central:** un embedding convierte texto en un vector donde *cercanía = significado parecido*. Así "cargo no reconocido" y "transacción que no hice" quedan cerca aunque no compartan palabras. Un **vector store** guarda esos vectores e indexa para encontrar los k más cercanos rápido (ANN). Es la base de la búsqueda semántica sobre quejas.
**🎯 Ruta de lectura (~4–6 h):** *ChromaDB docs* (~1.5 h, el más simple para empezar) → *Vertex text embeddings* (~1 h, el modelo que genera los vectores) → *Vector Search overview* (~1.5 h, la versión gestionada/escala) → concepto de **chunking** (transversal, decídelo temprano).

- 📘 **① Esencial:** [ChromaDB — docs](https://docs.trychroma.com/) · [Vertex AI — Text embeddings](https://cloud.google.com/vertex-ai/generative-ai/docs/embeddings/get-text-embeddings)
- 📘 **② Referencia:** [Vertex AI **Vector Search** (2.0 GA)](https://cloud.google.com/vertex-ai/docs/vector-search/overview) · [pgvector en Cloud SQL/AlloyDB](https://cloud.google.com/blog/products/databases/using-pgvector-llms-and-langchain-with-google-cloud-databases)
- 📄 **Paper:** *[Efficient Estimation of Word Representations (word2vec)](https://arxiv.org/abs/1301.3781)* — Mikolov et al.
- 📚 *Hands-On Large Language Models* — Alammar & Grootendorst (embeddings y búsqueda semántica)
- 🔀 **Variantes:** ChromaDB (local) vs **Vertex Vector Search** (gestionado) vs pgvector (SQL) vs FAISS; 🔁 AWS = **OpenSearch Serverless**; ¿ScaNN vs HNSW? estrategia de **chunking**.

## 5.2 RAG (Retrieval-Augmented Generation)
**🧠 Idea central:** en vez de que el LLM invente, primero **recuperas** los fragmentos relevantes (de las quejas) y se los das como contexto para que responda **citando evidencia**. Resuelve alucinaciones y datos privados/actuales sin reentrenar. La calidad depende tanto del *retrieval* como de la *generación* — por eso se evalúan por separado (5.4).
**🎯 Ruta de lectura (~2–3 días):** *LangChain RAG tutorial* (~4 h, constrúyelo mínimo) → paper fundacional de RAG (~1 h, el modelo mental) → *RAG Engine* de Vertex (~2 h, la versión gestionada, como variante) → avanzado: hybrid search + re-ranking (~3 h) cuando el RAG naïve se quede corto.

- 📘 **① Esencial:** [LangChain — RAG tutorial](https://docs.langchain.com/oss/python/langchain/rag) · [Vertex AI **RAG Engine**](https://cloud.google.com/vertex-ai/generative-ai/docs/rag-engine/rag-overview)
- 📘 **② Referencia:** [Retrievers (LangChain)](https://docs.langchain.com/oss/python/integrations/retrievers) · [Google: RAG con Vertex AI](https://cloud.google.com/architecture/rag-capable-gen-ai-app-using-vertex-ai)
- 📘 **③ Avanzada:** [Ranking API (re-ranking)](https://cloud.google.com/generative-ai-app-builder/docs/ranking) · chunking avanzado
- 📄 **Paper:** *[Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks](https://arxiv.org/abs/2005.11401)* — Lewis et al. (2020)
- 📚 *AI Engineering* — Chip Huyen (2025; **el** libro del rol) · *Relevant Search* — Turnbull & Berryman (fundamentos de IR)
- 🔀 **Variantes:** RAG *naïve* vs hybrid (denso + BM25) vs con re-ranking; a mano (LangChain+Chroma) vs **gestionado** (Vertex RAG Engine); ¿qué pasa sin evidencia? (grounding/abstención).

## 5.3 LLMs (Gemini en Vertex, Claude)
**🧠 Idea central:** el modelo generador que redacta la respuesta o el borrador de SAR. Elegirlo es un trade-off de *capacidad vs costo vs latencia*: un modelo Pro razona mejor, uno Flash es más barato y rápido. Los modelos **caducan** — hay que diseñar para poder cambiarlos.
**🎯 Ruta de lectura (~4–6 h):** *Modelos de Gemini* + *versions & lifecycle* (~1.5 h, ojo a las fechas de retiro) → *Introducción al prompt design* (~2 h) → *Claude en Vertex* (~1 h) como alternativa multi-modelo.

- 📘 **① Esencial:** [Gemini en Vertex — modelos](https://cloud.google.com/vertex-ai/generative-ai/docs/models) · [Model versions & lifecycle](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versions) *(hoy: Gemini 3.1 Pro / 3.x Flash; Gemini 2.5 se retira el 16-oct-2026)*
- 📘 **② Referencia:** [Prompt design con Gemini](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/prompts/introduction-prompt-design) · [Claude (Anthropic) en Vertex](https://cloud.google.com/vertex-ai/generative-ai/docs/partner-models/use-claude)
- 📚 *Prompt Engineering for LLMs* — John Berryman & Albert Ziegler
- 🔀 **Variantes:** Gemini vs Claude vs modelo abierto (Llama/Ollama local); ¿grande vs pequeño por costo/latencia? prompt engineering vs fine-tuning.

## 5.4 Evaluación de RAG (RAGAS) y tracing (Langfuse)
**🧠 Idea central:** "parece que responde bien" no es una métrica. RAGAS puntúa el RAG en ejes objetivos —*faithfulness* (¿se ciñe a la evidencia?), *answer relevancy*, *context precision/recall*— separando fallos de **recuperación** de fallos de **generación**. Langfuse te da la *traza* de cada consulta (prompt, contexto, respuesta, costo, latencia) para depurar. Sin esto no hay eval-gates en CI (Capa 7).
**🎯 Ruta de lectura (~1 día):** *RAGAS docs* + *conceptos de métricas* (~3 h, entiende cada métrica y qué diagnostica) → *Langfuse observability overview* + quickstart (~2 h, instrumenta tu RAG) → paper RAGAS para el fundamento.

- 📘 **① Esencial:** [RAGAS — docs](https://docs.ragas.io/en/stable/) · [Langfuse — Observability](https://langfuse.com/docs)
- 📘 **② Referencia:** [Métricas de RAGAS](https://docs.ragas.io/en/stable/concepts/metrics/) · [Langfuse tracing](https://langfuse.com/docs/observability/overview)
- 📄 **Paper:** *[RAGAS: Automated Evaluation of RAG](https://arxiv.org/abs/2309.15217)* — Es et al.
- 📚 *AI Engineering* — Chip Huyen (capítulo de evaluación)
- 🔀 **Variantes:** RAGAS vs LLM-as-judge propio vs golden dataset; evaluar retrieval vs generación por separado; Langfuse vs LangSmith.

---

# Capa 6 — Agentes (Agente Investigador de Fraude)

## 6.1 LangGraph (+ LangChain)
**🧠 Idea central:** un agente es un LLM que **decide qué herramientas usar** en bucle hasta resolver una tarea. LangGraph modela eso como un **grafo de estado**: nodos (pasos/decisiones) y aristas (flujo), con memoria y puntos de control. Da lo que un agente "suelto" no: pasos deterministas donde los necesitas, y *human-in-the-loop* para aprobar acciones sensibles (como firmar un SAR). Orquesta: consulta transacción → puntúa → busca quejas similares (RAG) → redacta borrador.
**🎯 Ruta de lectura (~2–3 días):** haz el curso *Intro to LangGraph* de LangChain Academy (~1 día, gratis, el tema es muy visual) → *Overview* + *Quickstart* (~3 h, en paralelo) → *State/nodes/edges* + *tool calling* (~4 h, el núcleo) → *human-in-the-loop* + *persistence* (~3 h, lo que lo hace apto para banca) → paper ReAct para el patrón de razonamiento.

- 📘 **① Esencial:** [LangGraph — Overview](https://docs.langchain.com/oss/python/langgraph/overview) · [Quickstart](https://docs.langchain.com/oss/python/langgraph/quickstart) *(docs unificadas en docs.langchain.com; LangChain/LangGraph v1.0)*
- 📘 **② Referencia:** [Graph API (state/nodes/edges)](https://docs.langchain.com/oss/python/langgraph/graph-api) · [Tool calling](https://docs.langchain.com/oss/python/langchain/tools) · [API reference](https://reference.langchain.com/python/langgraph/)
- 📘 **③ Avanzada:** [Human-in-the-loop](https://docs.langchain.com/oss/python/langgraph/add-human-in-the-loop) · [Persistence / checkpointing](https://docs.langchain.com/oss/python/langgraph/persistence) · [Multi-agent](https://docs.langchain.com/oss/python/langgraph/multi-agent)
- 📄 **Paper:** *[ReAct: Synergizing Reasoning and Acting in Language Models](https://arxiv.org/abs/2210.03629)* — Yao et al. (2022)
- 📚 *AI Engineering* — Chip Huyen (capítulo de agentes)
- 🎓 [LangChain Academy — Intro to LangGraph](https://academy.langchain.com/courses/intro-to-langgraph) (gratis)
- 🔀 **Variantes:** grafo explícito (LangGraph) vs ReAct suelto vs workflow determinista; ¿cuándo un agente sí y cuándo basta una cadena? human-in-the-loop para aprobar el SAR.

---

# Capa 7 — MLOps, CI/CD y despliegue

## 7.1 FastAPI + Docker + Artifact Registry
**🧠 Idea central:** FastAPI expone tu modelo/RAG como API HTTP (con validación y docs automáticas vía Pydantic). Docker empaqueta app + dependencias en una imagen reproducible ("funciona en mi máquina" → funciona en cualquier lado). Artifact Registry es el almacén de esas imágenes en GCP.
**🎯 Ruta de lectura (~1 día):** tutorial de FastAPI (~4 h, excelente y práctico) → *Docker get started* (~3 h, construye y corre una imagen) → Artifact Registry (~1 h, push/pull).

- 📘 **① Esencial:** [FastAPI](https://fastapi.tiangolo.com/) · [Docker — Get started](https://docs.docker.com/get-started/) · [Artifact Registry](https://cloud.google.com/artifact-registry/docs)
- 📚 *Building Python Microservices with FastAPI* — Abdulazeez Adeshina · *Docker Deep Dive* — Nigel Poulton
- 🔀 **Variantes:** FastAPI vs Flask; multi-stage builds; ¿imagen slim vs distroless?

## 7.2 Cloud Run (despliegue serverless)
**🧠 Idea central:** despliega un contenedor y Google lo escala solo (incluso a cero cuando no hay tráfico — pagas por uso). Ideal para la API de scoring/chat sin gestionar servidores. El precio: *cold starts* y límites de request/tiempo.
**🎯 Ruta de lectura (~3–4 h):** *What is Cloud Run* (~45 min) → *Deploy a container* (~1.5 h, despliega tu imagen) → *continuous deployment desde Git* (~1 h, conecta con CI de 7.3).

- 📘 **① Esencial:** [Cloud Run overview](https://cloud.google.com/run/docs/overview/what-is-cloud-run) · [Deploy de un contenedor](https://cloud.google.com/run/docs/deploying)
- 📘 **② Referencia:** [CD desde Git](https://cloud.google.com/run/docs/continuous-deployment-with-cloud-build) · [Concurrencia y autoscaling](https://cloud.google.com/run/docs/about-concurrency)
- 🔀 **Variantes:** 🔁 AWS = **ECS/Fargate** o Lambda; Cloud Run vs GKE vs VM; cold starts; ¿async/streaming para LLM?

## 7.3 CI/CD con GitHub Actions + eval-gates
**🧠 Idea central:** automatizar *"si el código pasa las pruebas, se despliega solo"*. Lo distintivo en IA es el **eval-gate**: además de tests de código, corres RAGAS en CI y **bloqueas el deploy si la calidad del RAG cae** de un umbral. Aquí vive la diferencia entre DevOps, MLOps y LLMOps.
**🎯 Ruta de lectura (~1 día):** *GitHub Actions quickstart* (~2 h, escribe un workflow) → *workflows y jobs* (~2 h) → *auth a GCP con Workload Identity Federation* (~1.5 h, sin claves estáticas) → diseña el eval-gate con umbral RAGAS.

- 📘 **① Esencial:** [GitHub Actions — docs](https://docs.github.com/en/actions) · [Quickstart](https://docs.github.com/en/actions/writing-workflows/quickstart)
- 📘 **② Referencia:** [Workflows y jobs](https://docs.github.com/en/actions/using-workflows) · [Auth a GCP (WIF)](https://github.com/google-github-actions/auth)
- 📚 *Practical MLOps* — Noah Gift & Alfredo Deza · *Introducing MLOps* — Treveil et al.
- 🔀 **Variantes:** **DevOps vs MLOps vs LLMOps**; eval-gate con umbral RAGAS; tests de código vs datos vs modelo.

## 7.4 Terraform (IaC)
**🧠 Idea central:** describes tu infraestructura en archivos versionados (`.tf`) y Terraform la crea/actualiza para que coincida (*infra como código*). Reproducible, revisable en PR, destruible de un comando — clave para no dejar recursos caros encendidos.
**🎯 Ruta de lectura (~4–6 h):** *Get Started (Google Cloud)* (~2 h, crea recursos de verdad) → provider `google` como referencia → *state remoto en GCS* + módulos (~2 h).

- 📘 **① Esencial:** [Terraform — Get Started (GCP)](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started) · [Provider google](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- 📚 *Terraform: Up & Running* — Yevgeniy Brikman
- 🔀 **Variantes:** Terraform vs gcloud/Deployment Manager; state remoto; módulos reutilizables.

## 7.5 Registro de experimentos (MLflow / Vertex / W&B)
**🧠 Idea central:** sin registro, cada experimento se pierde. Estas herramientas guardan params, métricas y artefactos de cada corrida para comparar y **reproducir** el mejor modelo — y promoverlo a producción con trazabilidad.
**🎯 Ruta de lectura (~3–4 h):** *MLflow docs* tracking + registry (~2 h) → *W&B* quickstart (~1 h) como alternativa de experimentación.

- 📘 **① Esencial:** [MLflow — docs](https://mlflow.org/docs/latest/index.html) · [Weights & Biases — docs](https://docs.wandb.ai/)
- 🔀 **Variantes:** MLflow (OSS, portable) vs Vertex Model Registry (nativo) vs W&B; ¿qué registrar: params, métricas, artefactos, lineage?

## 7.6 Frontend (React) + pruebas de carga
**🧠 Idea central:** React construye el dashboard del equipo antifraude con componentes reutilizables y estado reactivo. Las pruebas de carga (Locust/k6) simulan muchos usuarios para saber *hasta dónde aguanta* la API antes de romperse.
**🎯 Ruta de lectura (~1 día):** *react.dev* Learn (~4 h, hasta estado y efectos) → Locust **o** k6 quickstart (~2 h, elige uno) → GKE solo si Cloud Run se queda corto.

- 📘 **① Esencial:** [React — docs](https://react.dev/) · [Locust](https://docs.locust.io/en/stable/) · [k6](https://grafana.com/docs/k6/latest/)
- 📚 *The Road to React* — Robin Wieruch
- 🔀 **Variantes:** React vs Streamlit (dashboard rápido); Locust (Python) vs k6 (JS); ¿[GKE / Kubernetes](https://cloud.google.com/kubernetes-engine/docs) cuando Cloud Run no basta?

---

# Capa 8 — Seguridad (datos + IA) y observabilidad

## 8.1 Seguridad de datos (IAM, Secret Manager, DLP/PII)
**🧠 Idea central:** tres pilares. **IAM** con *menor privilegio* (cada identidad solo lo que necesita). **Secret Manager** para no poner claves/API keys en el código. **DLP (Sensitive Data Protection)** para detectar y enmascarar PII (nombres, tarjetas) en las quejas antes de que entren al RAG.
**🎯 Ruta de lectura (~4–5 h):** *IAM overview* + *usar IAM de forma segura* (~2 h, menor privilegio) → *Secret Manager* (~1 h, práctico) → *DLP overview* (~1.5 h, clave porque tus quejas traen PII).

- 📘 **① Esencial:** [IAM overview](https://cloud.google.com/iam/docs/overview) · [Secret Manager](https://cloud.google.com/secret-manager/docs/overview) · [Sensitive Data Protection (DLP)](https://cloud.google.com/sensitive-data-protection/docs)
- 📘 **② Referencia:** [Roles predefinidos](https://cloud.google.com/iam/docs/understanding-roles) · [Menor privilegio](https://cloud.google.com/iam/docs/using-iam-securely)
- 🔀 **Variantes:** roles predefinidos vs custom; service accounts vs Workload Identity; ¿enmascarar/tokenizar PII antes del RAG?

## 8.2 Seguridad de IA (OWASP LLM Top 10, guardrails, prompt injection)
**🧠 Idea central:** un asistente que lee quejas de clientes es **superficie de ataque**: una queja podría contener *"ignora tus instrucciones y…"* (**prompt injection**, riesgo #1 del OWASP LLM Top 10). Los **guardrails** son barreras de entrada (validar el input) y de salida (filtrar la respuesta) — defensa en profundidad. Aquí estaba tu punto ciego de entrevistas; vale doble.
**🎯 Ruta de lectura (~1 día):** *OWASP LLM Top 10* entero (~2 h, es la biblia del tema) → foco en *prompt injection* (~1 h) → *NeMo Guardrails overview* (~2 h) y *Llama Guard* (~1 h) como implementaciones → *Developer's Playbook* de Wilson como libro guía.

- 📘 **① Esencial:** [OWASP Top 10 for LLM Applications](https://genai.owasp.org/llm-top-10/) · [NeMo Guardrails — docs](https://docs.nvidia.com/nemo/guardrails/latest/about/overview.html)
- 📘 **② Referencia:** [Llama Guard (model card)](https://huggingface.co/meta-llama/Llama-Guard-3-8B) · [Vertex AI safety filters](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/configure-safety-filters)
- 📚 *The Developer's Playbook for Large Language Model Security* — Steve Wilson (O'Reilly)
- 📄 **Artículo:** [OWASP — Prompt Injection](https://genai.owasp.org/llmrisk/llm01-prompt-injection/)
- 🔀 **Variantes:** **NeMo Guardrails** vs **Llama Guard** vs filtros nativos de Vertex; input rails + output rails; 🔁 AWS = **Bedrock Guardrails**.

## 8.3 Observabilidad y drift (Cloud Monitoring, Evidently)
**🧠 Idea central:** en producción el modelo se degrada porque el mundo cambia (*drift*): las distribuciones de entrada se mueven (*data drift*) o la relación X→y cambia (*concept drift*) — y en fraude los defraudadores cambian de táctica a propósito. Evidently detecta esos cambios y dispara alertas/reentrenamiento; Cloud Logging/Monitoring vigilan la salud del sistema.
**🎯 Ruta de lectura (~5–6 h):** *Evidently docs* + presets de drift (~2 h, muy visual) → *Vertex Model Monitoring* (~1.5 h, la versión gestionada) → *Cloud Monitoring* (~1.5 h, dashboards y alertas). Capítulos de monitoreo de Chip Huyen para el marco conceptual.

- 📘 **① Esencial:** [Cloud Logging](https://cloud.google.com/logging/docs) · [Cloud Monitoring](https://cloud.google.com/monitoring/docs) · [Evidently — docs](https://docs.evidentlyai.com/)
- 📘 **② Referencia:** [Vertex Model Monitoring](https://cloud.google.com/vertex-ai/docs/model-monitoring/overview) · [Evidently (GitHub)](https://github.com/evidentlyai/evidently)
- 📚 *Designing Machine Learning Systems* — Chip Huyen (monitoreo y data distribution shifts)
- 🔀 **Variantes:** data drift vs concept drift vs prediction drift; ¿cuándo reentrenar? rollback de modelo; alertas de negocio.

---

# 📚 Estantería base (los 6 libros que cruzan todo el proyecto)

Si solo pudieras sacar 6 de la biblioteca:

| Libro | Autor(es) | Cubre |
|---|---|---|
| *Fundamentals of Data Engineering* | Reis & Housley | Capas 1–3 |
| *Designing Data-Intensive Applications* | Martin Kleppmann | sistemas de datos (transversal) |
| *Hands-On Machine Learning…* | Aurélien Géron | Capa 4 |
| *AI Engineering* | Chip Huyen | Capas 5–6 (RAG, evals, agentes) |
| *Designing Machine Learning Systems* | Chip Huyen | Capas 4, 7, 8 (producción) |
| *The Developer's Playbook for LLM Security* | Steve Wilson | Capa 8 (seguridad de IA) |

---

> **Método (recordatorio):** para cada componente → 🧠 entiende la idea central → 🎓 curso corto si hace falta → 📘 doc oficial siguiendo la ruta de lectura → implementación mínima (el manual) → 🔀 variantes (romper y reconstruir) → producción/seguridad/eval → documentación propia. La prueba de dominio no es *"lo hice"*, sino *"puedo justificar por qué elegí cada pieza y cambiarla si el requisito cambia"*.
>
> **Fuentes verificadas jul-2026.** Los productos de nube evolucionan rápido (Vertex AI ↔ "Gemini Enterprise Agent Platform", Composer 3 / Airflow 3.1, docs de LangChain unificadas en docs.langchain.com). Si un enlace cambia, busca el término en el sitio oficial y actualiza esta fecha.
