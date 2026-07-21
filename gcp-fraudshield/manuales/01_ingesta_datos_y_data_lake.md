# Manual 01 — Ingesta de datos y Data Lake

> **Objetivo:** Traer los datos del caso de fraude bancario (transacciones masivas + narrativas cualitativas de quejas de clientes) desde fuentes públicas, almacenarlos en un **Data Lake** (Cloud Storage) y cargarlos en un **Data Warehouse** (BigQuery), dejándolos listos para consultar con SQL. Aprenderás ingesta, organización de un Data Lake por capas y manejo de gran volumen — sobre un caso real de detección de fraude.
>
> **Tiempo estimado:** 4–6 horas.
> **Prerrequisito:** Manual 00 completo (entorno cloud listo, repo `fraudshield` clonado).
> **Requisitos del cargo que cubre:** prospección de fuentes (datos estructurados y no estructurados), gran volumen, SQL relacional, fundamentos de Data Engineering.

---

## 🖱️ / ⌨️ Cómo leer este manual (UI + CLI)

Este manual está escrito en formato **doble camino**. Cada paso operativo trae:

- 🖱️ **Por la Consola (UI):** clic por clic en la consola web de GCP (`console.cloud.google.com`). Ideal para *entender visualmente* qué hace cada paso, igual que la consola de AWS.
- ⌨️ **Equivalente en CLI:** el mismo resultado con un comando en **Cloud Shell**. Es lo que se *espera* que domines en una entrevista de Ingeniero ML — te da velocidad y reproducibilidad.

👉 **Puedes completar el manual entero solo con la UI.** El CLI está al lado como referencia y "músculo" para entrevistas. Elige uno, o haz la UI primero y luego repite por CLI para afianzar.

⚠️ **Una honestidad importante:** hay dos transformaciones (transacciones y quejas) que *tradicionalmente* se hacían con un script de Python. Aquí las resolvemos **con SQL dentro de BigQuery** (enfoque **ELT**: *Extract, Load, Transform*), que es más *cloud-native* y **100% por UI**. Ambos caminos terminan en **exactamente las mismas tablas**, así que los manuales siguientes funcionan igual. El camino Python queda documentado como variante avanzada.

---

## 📋 Tabla de contenido

1. [Conceptos previos](#1-conceptos-previos)
2. [El caso de negocio y los datasets](#2-datasets)
3. [Descargar los datasets](#3-descargar)
4. [Crear el Data Lake (Cloud Storage)](#4-data-lake)
5. [Subir los datos al Data Lake](#5-subir)
6. [Crear el Data Warehouse (BigQuery)](#6-bigquery)
7. [Cargar y transformar las transacciones](#7-transacciones)
8. [Cargar y filtrar las quejas (datos no estructurados)](#8-quejas)
9. [Tus primeras 10 consultas SQL de fraude](#9-sql)
10. [Variante avanzada: automatizar con Python/CLI](#10-avanzado)
11. [Commit a GitHub](#11-commit)
12. [✅ Checklist final](#12-checklist)
13. [🛟 Solución de problemas](#13-troubleshooting)
14. [📖 Glosario](#14-glosario)

---

## 1. Conceptos previos

📖 **Ingesta (ingestion):** el proceso de traer datos desde una fuente externa a tu plataforma. Es la "E" de ETL/ELT (Extract).

📖 **Data Lake por capas (medallion):** organizamos el lake en zonas según el grado de procesamiento:
- **`raw/` (bronze):** datos tal cual llegan, sin tocar. Si algo sale mal, siempre puedes volver aquí.
- **`staging/` (silver):** datos limpios/normalizados.
- **`curated/` (gold):** datos listos para consumo (modelos, dashboards).
En este manual llenamos la zona **`raw/`**. Las capas silver/gold las hará dbt (Manual 02).

📖 **Cloud Storage (GCS):** servicio de almacenamiento de objetos (archivos) de GCP. Los archivos viven en **buckets** (cubetas) con nombre **único en todo el mundo**.

📖 **BigQuery:** el Data Warehouse serverless de GCP. Organiza datos en **datasets** (≈ esquemas/carpetas) que contienen **tablas**. Consultas con SQL estándar. Cobra por **datos escaneados** (1 TB/mes gratis).

📖 **ETL vs ELT (clave para el cargo y para este manual):**
- **ETL:** *Extract → Transform → Load*. Transformas los datos **antes** de cargarlos (ej. con Python en tu máquina). Es lo que hacía la versión anterior de este manual.
- **ELT:** *Extract → Load → Transform*. Cargas los datos **crudos** al warehouse y transformas **dentro** con SQL. Es el enfoque moderno en la nube: aprovecha la potencia de BigQuery, no necesitas un entorno de cómputo local y **se hace por UI**. Es el camino principal de este manual.

📖 **Datos estructurados vs no estructurados (clave para el cargo):**
- **Estructurados:** filas y columnas con tipos definidos → las **transacciones** (monto, tipo, cuentas, etiqueta de fraude).
- **No estructurados:** texto libre sin esquema fijo → las **narrativas de quejas** de clientes. Aquí harás, más adelante, **consultas semánticas y cualitativas** (Manual 05, RAG).

💡 **El flujo de este manual:** Kaggle/CFPB → descargar → subir a Cloud Storage (`raw/`) → cargar crudo a BigQuery → transformar con SQL → consultar.

---

## 2. Datasets

### 🏦 El caso de negocio
Simulamos el trabajo del **departamento de fraude de un banco**. Necesitamos dos tipos de datos, como en la realidad:

1. **Transacciones** (estructurado, gran volumen) → para detectar patrones de fraude y entrenar el modelo.
2. **Quejas / narrativas de clientes** (no estructurado, texto) → para que un analista pueda hacer **consultas semánticas y cualitativas** ("¿qué tipo de fraude reportan más los clientes?", "resume las quejas sobre transferencias no autorizadas").

### 📦 Dataset A — Transacciones (PaySim)
**"Synthetic Financial Datasets For Fraud Detection"** de Kaggle (autor: *ealaxi*, dataset **PaySim**).
- Simula transacciones de dinero móvil basadas en datos reales de un banco africano (anonimizadas).
- **~6.3 millones de filas** → ideal para gran volumen, Data Lake/Warehouse y entrenamiento de fraude.
- Una sola CSV (~470 MB) llamado `PS_20174392719_1491204439457_log.csv`.
- Columnas:

| Columna | Significado |
|---|---|
| `step` | Unidad de tiempo (1 step = 1 hora; total 744 = 30 días) |
| `type` | Tipo de transacción: `CASH_IN`, `CASH_OUT`, `DEBIT`, `PAYMENT`, `TRANSFER` |
| `amount` | Monto de la transacción |
| `nameOrig` | Cuenta de origen |
| `oldbalanceOrg` / `newbalanceOrig` | Saldo del origen antes/después |
| `nameDest` | Cuenta de destino |
| `oldbalanceDest` / `newbalanceDest` | Saldo del destino antes/después |
| `isFraud` | **Etiqueta:** 1 = transacción fraudulenta, 0 = legítima |
| `isFlaggedFraud` | 1 = el sistema antiguo la marcó como sospechosa |

- URL: `https://www.kaggle.com/datasets/ealaxi/paysim1`

💡 **Por qué PaySim:** el fraude está en `TRANSFER` y `CASH_OUT`; las clases están **muy desbalanceadas** (~0.13% fraude), justo el reto real de detección de fraude (Manual 04).

### 📰 Dataset B — Quejas de clientes (texto / no estructurado)
**"Consumer Complaint Database" (CFPB)** — quejas reales de consumidores sobre productos y servicios financieros en EE.UU., con **narrativas en texto libre**.
- Contiene el campo **`Consumer complaint narrative`** (texto), además de `Product`, `Issue`, `Company`, `Date received`, etc.
- Muchas quejas son sobre **fraude, cargos no autorizados, robo de identidad y estafas** → perfecto para consultas semánticas/cualitativas y RAG.
- Fuente oficial (tiene descarga por UI): `https://www.consumerfinance.gov/data-research/consumer-complaints/`
- En Kaggle búscalo como **"consumer complaint database"** (varios mirrors).
- 💡 Es un dataset grande. En este manual lo cargamos **crudo** a BigQuery y lo **filtramos con SQL** (solo quejas con narrativa y de temas de fraude), en vez de filtrarlo antes con Python.

> **Nota:** Los slugs de Kaggle a veces cambian. Si un enlace no funciona, busca el dataset por nombre en la web de Kaggle.

---

## 3. Descargar

Necesitas bajar los dos datasets a tu computador (o a Cloud Shell). Elige el camino que prefieras.

### 3.1 — Transacciones (PaySim)

🖱️ **Por la web (UI, sin credenciales de API):**
1. Entra a `https://www.kaggle.com/datasets/ealaxi/paysim1` e inicia sesión (o crea una cuenta gratis).
2. Clic en el botón **Download** (arriba a la derecha del dataset).
3. Se descarga un `.zip` a tu carpeta de Descargas. Descomprímelo: obtendrás un CSV grande (`PS_..._log.csv`, ~470 MB).
4. **Renómbralo** a `transactions.csv` para simplificar.

⌨️ **Equivalente en CLI (Cloud Shell, con API de Kaggle):**
```bash
# 1) Token de Kaggle: en kaggle.com → tu foto → Settings → API → "Create New Token"
#    (descarga kaggle.json). Súbelo a Cloud Shell con el menú ⋮ → Upload, y colócalo:
mkdir -p ~/.kaggle && mv ~/kaggle.json ~/.kaggle/kaggle.json && chmod 600 ~/.kaggle/kaggle.json
pip install --user kaggle

# 2) Descargar y preparar
cd ~/fraudshield/extract && mkdir -p data/transactions && cd data/transactions
kaggle datasets download -d ealaxi/paysim1
unzip -q paysim1.zip
mv PS_*.csv transactions.csv
rm -f paysim1.zip          # Cloud Shell solo tiene 5 GB: libera espacio
ls -lh transactions.csv
```
💡 El token de API **solo hace falta para el camino CLI**. Por la web basta el botón Download.

### 3.2 — Quejas (CFPB)

🖱️ **Por la web (UI):**
1. Entra a `https://www.consumerfinance.gov/data-research/consumer-complaints/search/` → botón **Export data** → **CSV** (o descarga el mirror de Kaggle "consumer complaint database").
2. Descomprime si viene en `.zip`. Obtendrás un CSV grande de quejas.
3. Renómbralo a `complaints_full.csv`.

⌨️ **Equivalente en CLI (Cloud Shell):**
```bash
cd ~/fraudshield/extract && mkdir -p data/complaints && cd data/complaints
# Verifica el slug actual en Kaggle; ejemplo:
kaggle datasets download -d selener/consumer-complaint-database
unzip -q *.zip
mv *.csv complaints_full.csv 2>/dev/null
rm -f *.zip
ls -lh complaints_full.csv
```

### ✅ Checkpoint 3
- Tienes `transactions.csv` (~470 MB) y `complaints_full.csv` en tu PC o en Cloud Shell.

---

## 4. Data Lake

Creamos el bucket (Data Lake) y sus zonas `raw/staging/curated`.

### Paso 4.1 — Crear el bucket

🖱️ **Por la Consola (UI):**
1. Menú de navegación **☰** → **Cloud Storage** → **Buckets** → botón **+ CREATE** (Crear).
2. **Name:** debe ser **único en todo el mundo**. Usa tu Project ID como prefijo, ej. `mi-proyecto-123-datalake`. → **Continue**.
3. **Location type:** *Region* → **`us-central1`** (misma región que BigQuery, evita costos de transferencia). → **Continue**.
4. **Storage class:** *Standard*. → **Continue**.
5. **Access control:** marca **Uniform** (simplifica permisos). → **Continue**.
6. Deja el resto por defecto → **CREATE**. (Si aparece un aviso de "Public access prevention", déjalo **activado**.)

⌨️ **Equivalente en CLI (Cloud Shell):**
```bash
export PROJECT_ID=$(gcloud config get-value project)
export BUCKET="gs://${PROJECT_ID}-datalake"
gcloud storage buckets create $BUCKET \
  --location=us-central1 \
  --uniform-bucket-level-access
```

### Paso 4.2 — Crear las zonas (carpetas) del Data Lake

🖱️ **Por la Consola (UI):**
1. Entra a tu bucket recién creado.
2. Botón **CREATE FOLDER** → nombre `raw` → **CREATE**.
3. Repite para `staging` y `curated`.

⌨️ **Equivalente en CLI (Cloud Shell):**
```bash
echo "raw zone"     | gcloud storage cp - $BUCKET/raw/.keep
echo "staging zone" | gcloud storage cp - $BUCKET/staging/.keep
echo "curated zone" | gcloud storage cp - $BUCKET/curated/.keep
```
💡 En GCS las "carpetas" son un prefijo del nombre del objeto. Por eso en CLI creamos un archivo `.keep` dentro; por UI el botón *Create folder* lo hace por ti.

### ✅ Checkpoint 4
En **Cloud Storage → Buckets → tu bucket** ves las carpetas `raw/`, `staging/`, `curated/`.
CLI: `gcloud storage ls $BUCKET`.

---

## 5. Subir

Subimos los datos crudos a la zona **`raw/`**.

### Paso 5.1 — Subir transacciones y quejas

🖱️ **Por la Consola (UI):**
1. Entra al bucket → carpeta **`raw/`** → botón **CREATE FOLDER** → crea `transactions` y `complaints`.
2. Entra a `raw/transactions/` → botón **UPLOAD** → **Upload files** → selecciona `transactions.csv`. Espera a que suba (470 MB puede tardar según tu conexión).
3. Entra a `raw/complaints/` → **UPLOAD** → **Upload files** → selecciona `complaints_full.csv`.

⌨️ **Equivalente en CLI (Cloud Shell):**
```bash
gcloud storage cp ~/fraudshield/extract/data/transactions/transactions.csv \
  $BUCKET/raw/transactions/
gcloud storage cp ~/fraudshield/extract/data/complaints/complaints_full.csv \
  $BUCKET/raw/complaints/
```
💡 **¿Subida lenta por UI?** Para archivos grandes, Cloud Shell suele ser más rápido porque sube desde la red de Google. Si subes por navegador, no cierres la pestaña hasta que termine.

### ✅ Checkpoint 5
En `raw/transactions/` está el CSV de transacciones y en `raw/complaints/` el de quejas.
CLI: `gcloud storage ls -r $BUCKET/raw/`.

---

## 6. BigQuery

Creamos el dataset (la "carpeta" de tablas) de la capa raw.

### Paso 6.1 — Crear el dataset `fraud_raw`

🖱️ **Por la Consola (UI):**
1. Menú **☰** → **BigQuery** → **Studio**.
2. En el panel **Explorer** (izquierda), pasa el mouse sobre el nombre de tu **proyecto** → clic en el menú **⋮** → **Create dataset**.
3. **Dataset ID:** `fraud_raw`.
4. **Location type:** *Region* → **`us-central1`** (¡debe coincidir con el bucket!).
5. **CREATE DATASET**.

⌨️ **Equivalente en CLI (Cloud Shell):**
```bash
export PROJECT_ID=$(gcloud config get-value project)
bq --location=us-central1 mk --dataset \
  --description "Capa raw de FraudShield" \
  ${PROJECT_ID}:fraud_raw
```

### ✅ Checkpoint 6
En el Explorer de BigQuery, al expandir tu proyecto, aparece `fraud_raw`.
CLI: `bq ls`.

---

## 7. Transacciones

Vamos a **cargar el CSV crudo** a una tabla y luego **transformarlo con SQL** (renombrar columnas a snake_case y crear `hour_of_day`). Este es el patrón **ELT**.

### Paso 7.1 — Cargar el CSV crudo a una tabla temporal

🖱️ **Por la Consola (UI):**
1. En **BigQuery → Explorer**, expande tu proyecto → pasa el mouse sobre **`fraud_raw`** → menú **⋮** → **Create table**.
2. **Source → Create table from:** *Google Cloud Storage*.
3. **Select file from GCS bucket:** clic en **BROWSE** → navega a `raw/transactions/transactions.csv` → selecciónalo. **File format:** *CSV*.
4. **Destination → Table:** `_transactions_raw` (el guion bajo indica que es temporal).
5. **Schema:** marca **Auto detect**.
6. **Advanced options → Header rows to skip:** `1`.
7. **CREATE TABLE**. Tarda 1–3 min.

⌨️ **Equivalente en CLI (Cloud Shell):**
```bash
bq load --source_format=CSV --autodetect --skip_leading_rows=1 --replace \
  fraud_raw._transactions_raw "$BUCKET/raw/transactions/transactions.csv"
```
💡 Con autodetect, BigQuery infiere los tipos y **conserva los nombres originales** (`nameOrig`, `isFraud`, …).

### Paso 7.2 — Transformar con SQL → tabla final `transactions`

Abre un editor SQL (**BigQuery → + Compose new query** / `SQL query`), pega y **RUN**:

```sql
-- ELT: renombra columnas a snake_case y crea la feature hour_of_day.
-- Deja la tabla final idéntica a la del camino Python (los Manuales 02+ dependen de estos nombres).
CREATE OR REPLACE TABLE `fraud_raw.transactions` AS
SELECT
  step,
  type,
  amount,
  nameOrig        AS name_orig,
  oldbalanceOrg   AS old_balance_orig,
  newbalanceOrig  AS new_balance_orig,
  nameDest        AS name_dest,
  oldbalanceDest  AS old_balance_dest,
  newbalanceDest  AS new_balance_dest,
  isFraud         AS is_fraud,
  isFlaggedFraud  AS is_flagged_fraud,
  MOD(step, 24)   AS hour_of_day      -- hora del día (feature simple)
FROM `fraud_raw._transactions_raw`;
```

> 💡 Si el autodetect nombró alguna columna distinto, revisa el esquema (clic en la tabla `_transactions_raw` → pestaña **SCHEMA**) y ajusta los nombres del `SELECT`.

Opcional — borra la tabla temporal para dejar limpio:
```sql
DROP TABLE `fraud_raw._transactions_raw`;
```

### Paso 7.3 — Verificar la carga y la distribución de fraude
```sql
SELECT
  COUNT(*)                                  AS filas,
  SUM(is_fraud)                             AS fraudes,
  ROUND(SUM(is_fraud)/COUNT(*)*100, 4)      AS pct_fraude
FROM `fraud_raw.transactions`;
```
Deberías ver **~6.36M filas**, ~8,213 fraudes y **~0.13% de fraude**. 🎯 (Ese desbalance es el reto del Manual 04.)

### ✅ Checkpoint 7
La tabla `fraud_raw.transactions` existe con ~6.3M filas, columnas en snake_case y `hour_of_day`.

---

## 8. Quejas

Mismo patrón ELT: cargamos las quejas **crudas** y **filtramos con SQL** (solo las que tienen narrativa y son de temas de fraude). Estos son los **datos no estructurados**, base de las consultas semánticas del Manual 05.

### Paso 8.1 — Cargar el CSV crudo de quejas

🖱️ **Por la Consola (UI):**
1. **fraud_raw → ⋮ → Create table.** Source: *Google Cloud Storage* → **BROWSE** → `raw/complaints/complaints_full.csv`. **File format:** *CSV*.
2. **Destination → Table:** `_complaints_raw`.
3. **Schema:** *Auto detect*.
4. **Advanced options:**
   - **Header rows to skip:** `1`.
   - Marca **Allow quoted newlines** ✅ — **clave**: las narrativas tienen saltos de línea dentro del texto.
   - **Number of errors allowed:** `1000` (por si algunas filas vienen mal formadas).
5. **CREATE TABLE**.

⌨️ **Equivalente en CLI (Cloud Shell):**
```bash
bq load --source_format=CSV --autodetect --skip_leading_rows=1 --replace \
  --allow_quoted_newlines --max_bad_records=1000 \
  fraud_raw._complaints_raw "$BUCKET/raw/complaints/complaints_full.csv"
```

### Paso 8.2 — Revisar el nombre real de la columna de narrativa

El autodetect convierte `Consumer complaint narrative` → `Consumer_complaint_narrative` (espacios a guion bajo). Verifícalo: clic en `_complaints_raw` → pestaña **SCHEMA**, o:
```sql
SELECT column_name
FROM `fraud_raw`.INFORMATION_SCHEMA.COLUMNS
WHERE table_name = '_complaints_raw';
```

### Paso 8.3 — Filtrar con SQL → tabla final `complaints`

Ajusta los nombres de columna si tu esquema difiere, pega y **RUN**:

```sql
CREATE OR REPLACE TABLE `fraud_raw.complaints` AS
SELECT *
FROM `fraud_raw._complaints_raw`
WHERE Consumer_complaint_narrative IS NOT NULL          -- solo quejas con texto
  AND (
        LOWER(Issue)   LIKE '%fraud%'          OR
        LOWER(Issue)   LIKE '%scam%'           OR
        LOWER(Issue)   LIKE '%unauthorized%'   OR
        LOWER(Issue)   LIKE '%identity theft%' OR
        LOWER(Issue)   LIKE '%stolen%'         OR
        LOWER(Product) LIKE '%fraud%'
      )
LIMIT 50000;                                            -- liviano y suficiente para RAG
```

Opcional — limpiar:
```sql
DROP TABLE `fraud_raw._complaints_raw`;
```

### Paso 8.4 — Verificar
```sql
SELECT * FROM `fraud_raw.complaints` LIMIT 3;
```

🛟 *Si el filtro deja 0 filas:* tu mirror puede usar otros nombres de columna o ya venir filtrado. Revisa el esquema (Paso 8.2) y ajusta `Issue`/`Product`/`Consumer_complaint_narrative`. Algunos mirrors traen la columna simplemente como `narrative`.

### ✅ Checkpoint 8
La tabla `fraud_raw.complaints` existe y muestra narrativas de texto sobre temas de fraude.

---

## 9. SQL

Practica SQL analítico **sobre el caso de fraude**. Ejecuta cada consulta en el editor de BigQuery (**Compose new query → pega → RUN**) y entiéndela (las window functions y CTEs son oro para entrevistas). Guárdalas luego en `queries.sql`.

💡 **Tip de costo:** BigQuery cobra por datos escaneados; estas consultas son pequeñas frente al 1 TB gratis mensual. Evita `SELECT *` sin `LIMIT` sobre la tabla completa.

```sql
-- 1. Volumen total y tasa de fraude global
SELECT COUNT(*) AS total, SUM(is_fraud) AS fraudes,
       ROUND(SUM(is_fraud)/COUNT(*)*100, 4) AS pct_fraude
FROM `fraud_raw.transactions`;
```
```sql
-- 2. ¿En qué TIPOS de transacción ocurre el fraude? (insight clave)
SELECT type,
       COUNT(*) AS n,
       SUM(is_fraud) AS fraudes,
       ROUND(SUM(is_fraud)/COUNT(*)*100, 4) AS pct_fraude
FROM `fraud_raw.transactions`
GROUP BY type
ORDER BY fraudes DESC;
```
```sql
-- 3. Monto: comparación fraude vs legítimo
SELECT is_fraud,
       COUNT(*) AS n,
       ROUND(AVG(amount), 2) AS monto_promedio,
       ROUND(MAX(amount), 2) AS monto_max
FROM `fraud_raw.transactions`
GROUP BY is_fraud;
```
```sql
-- 4. Patrón temporal: tasa de fraude por hora del día
SELECT hour_of_day,
       COUNT(*) AS n,
       SUM(is_fraud) AS fraudes,
       ROUND(SUM(is_fraud)/COUNT(*)*100, 4) AS pct_fraude
FROM `fraud_raw.transactions`
GROUP BY hour_of_day
ORDER BY hour_of_day;
```
```sql
-- 5. FEATURE de velocidad: nº de transacciones acumuladas por cuenta origen (WINDOW)
SELECT name_orig, step, amount,
       COUNT(*) OVER (
         PARTITION BY name_orig ORDER BY step
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS tx_acumuladas_cuenta
FROM `fraud_raw.transactions`
WHERE name_orig IN (
  SELECT name_orig FROM `fraud_raw.transactions`
  WHERE is_fraud = 1 LIMIT 1
)
ORDER BY step
LIMIT 20;
```
```sql
-- 6. Tiempo desde la transacción anterior de la misma cuenta (LAG)
SELECT name_orig, step,
       step - LAG(step) OVER (PARTITION BY name_orig ORDER BY step) AS steps_desde_anterior,
       amount, is_fraud
FROM `fraud_raw.transactions`
WHERE type = 'TRANSFER' AND is_fraud = 1
ORDER BY name_orig, step
LIMIT 20;
```
```sql
-- 7. Señal de fraude / calidad: inconsistencia de saldos
--    En un retiro legítimo: old_balance_orig - amount ≈ new_balance_orig
SELECT
  COUNTIF(ABS(old_balance_orig - amount - new_balance_orig) > 1) AS saldos_inconsistentes,
  COUNT(*) AS total
FROM `fraud_raw.transactions`
WHERE type IN ('TRANSFER', 'CASH_OUT');
```
```sql
-- 8. Cuentas destino que más reciben transacciones fraudulentas (RANK)
SELECT name_dest, COUNT(*) AS fraudes_recibidos
FROM `fraud_raw.transactions`
WHERE is_fraud = 1
GROUP BY name_dest
ORDER BY fraudes_recibidos DESC
LIMIT 10;
```
```sql
-- 9. Calidad de datos: nulos y montos no válidos
SELECT
  COUNTIF(amount IS NULL) AS montos_nulos,
  COUNTIF(amount <= 0) AS montos_no_positivos,
  COUNTIF(type IS NULL) AS tipos_nulos
FROM `fraud_raw.transactions`;
```
```sql
-- 10. Consulta CUALITATIVA sobre las quejas (texto): temas más frecuentes
--     (búsqueda por palabra clave; la búsqueda SEMÁNTICA real llega en el Manual 05 con RAG)
SELECT
  COUNTIF(LOWER(Consumer_complaint_narrative) LIKE '%unauthorized%') AS no_autorizado,
  COUNTIF(LOWER(Consumer_complaint_narrative) LIKE '%scam%')         AS estafa,
  COUNTIF(LOWER(Consumer_complaint_narrative) LIKE '%identity%')     AS robo_identidad,
  COUNT(*) AS total_quejas
FROM `fraud_raw.complaints`;
```

> 💡 En la consulta 10, ajusta `Consumer_complaint_narrative` al nombre real de tu tabla (Paso 8.2).

### Paso 9.11 — Guardar las consultas en el repo
Crea `~/fraudshield/extract/queries.sql` y pega las 10 consultas con sus comentarios. Por UI puedes usar **Cloud Shell → Open Editor** para pegar cómodo; o crea el archivo en tu editor local.

### ✅ Checkpoint 9
Las 10 consultas corren sin error. Entiendes especialmente las **window functions** (5, 6) y la lógica de **inconsistencia de saldos** (7) — son argumentos potentes en entrevista para hablar de feature engineering de fraude.

---

## 10. Avanzado

> Esta sección es **opcional** y **solo por CLI/código**. Es el camino "tradicional" (ETL con Python) y una automatización reutilizable que **Airflow usará en el Manual 03**. Hazla si quieres músculo de código; el estado final es el mismo que ya lograste por UI.

### 10.1 — Variante ETL: convertir a Parquet con Python (opcional)

📖 **Parquet** pesa ~5–10x menos que CSV y BigQuery lo carga más rápido. Alternativa al Paso 7 si prefieres transformar **antes** de cargar. Se corre en Cloud Shell:
```bash
cat > ~/fraudshield/extract/csv_to_parquet.py << 'EOF'
"""Convierte el CSV de PaySim a Parquet por trozos (chunks), normaliza columnas y añade hour_of_day."""
import os, pandas as pd, pyarrow as pa, pyarrow.parquet as pq
IN  = os.path.expanduser("~/fraudshield/extract/data/transactions/transactions.csv")
OUT = os.path.expanduser("~/fraudshield/extract/data/transactions/transactions.parquet")
RENAME = {"nameOrig":"name_orig","oldbalanceOrg":"old_balance_orig","newbalanceOrig":"new_balance_orig",
          "nameDest":"name_dest","oldbalanceDest":"old_balance_dest","newbalanceDest":"new_balance_dest",
          "isFraud":"is_fraud","isFlaggedFraud":"is_flagged_fraud"}
writer, total = None, 0
for chunk in pd.read_csv(IN, chunksize=500_000):
    chunk = chunk.rename(columns=RENAME)
    chunk["hour_of_day"] = chunk["step"] % 24
    table = pa.Table.from_pandas(chunk, preserve_index=False)
    writer = writer or pq.ParquetWriter(OUT, table.schema)
    writer.write_table(table); total += len(chunk)
    print(f"  procesadas {total:,} filas...")
if writer: writer.close()
print(f"Listo: {OUT} ({total:,} filas)")
EOF

pip install --user pandas pyarrow
cd ~/fraudshield/extract && python3 csv_to_parquet.py
gcloud storage cp data/transactions/transactions.parquet $BUCKET/raw/transactions/
bq load --source_format=PARQUET --replace fraud_raw.transactions "$BUCKET/raw/transactions/*.parquet"
```

### 10.2 — Automatización idempotente (la usará Airflow en el Manual 03)
```bash
cat > ~/fraudshield/extract/load_to_bigquery.py << 'EOF'
"""Carga idempotente Cloud Storage -> BigQuery para FraudShield. Reutilizable por Airflow."""
import subprocess
PROJECT_ID = subprocess.check_output(["gcloud","config","get-value","project"], text=True).strip()
BUCKET  = f"gs://{PROJECT_ID}-datalake"
DATASET = "fraud_raw"

def run(cmd):
    print(">", " ".join(cmd)); subprocess.run(cmd, check=True)

def load_transactions():
    run(["bq","load","--source_format=CSV","--autodetect","--skip_leading_rows=1","--replace",
         f"{DATASET}._transactions_raw", f"{BUCKET}/raw/transactions/transactions.csv"])
    run(["bq","query","--use_legacy_sql=false", f"""
        CREATE OR REPLACE TABLE `{DATASET}.transactions` AS
        SELECT step, type, amount, nameOrig AS name_orig, oldbalanceOrg AS old_balance_orig,
               newbalanceOrig AS new_balance_orig, nameDest AS name_dest,
               oldbalanceDest AS old_balance_dest, newbalanceDest AS new_balance_dest,
               isFraud AS is_fraud, isFlaggedFraud AS is_flagged_fraud, MOD(step,24) AS hour_of_day
        FROM `{DATASET}._transactions_raw`"""])

def load_complaints():
    run(["bq","load","--source_format=CSV","--autodetect","--skip_leading_rows=1","--replace",
         "--allow_quoted_newlines","--max_bad_records=1000",
         f"{DATASET}._complaints_raw", f"{BUCKET}/raw/complaints/complaints_full.csv"])
    run(["bq","query","--use_legacy_sql=false", f"""
        CREATE OR REPLACE TABLE `{DATASET}.complaints` AS
        SELECT * FROM `{DATASET}._complaints_raw`
        WHERE Consumer_complaint_narrative IS NOT NULL
          AND (LOWER(Issue) LIKE '%fraud%' OR LOWER(Issue) LIKE '%scam%'
            OR LOWER(Issue) LIKE '%unauthorized%' OR LOWER(Issue) LIKE '%identity theft%'
            OR LOWER(Issue) LIKE '%stolen%' OR LOWER(Product) LIKE '%fraud%')
        LIMIT 50000"""])

if __name__ == "__main__":
    load_transactions(); load_complaints()
    print("Ingesta de FraudShield completada.")
EOF

cd ~/fraudshield/extract && python3 load_to_bigquery.py
```

### ✅ Checkpoint 10 (opcional)
El script corre completo e imprime "Ingesta de FraudShield completada." y deja las mismas tablas `transactions` y `complaints`.

---

## 11. Commit

⚠️ **Nunca subas datos crudos ni credenciales a GitHub.** Solo subimos código y las consultas.

🖱️ **Por la UI (GitHub web / VS Code):** arrastra `queries.sql` (y los scripts opcionales) al repo, o usa el control de versiones de VS Code para *commit + push*. Asegúrate de que `.gitignore` excluya los datos.

⌨️ **Equivalente en CLI:**
```bash
cd ~/fraudshield
cat >> .gitignore << 'EOF'

# Datos locales (no subir)
extract/data/
*.zip
*.parquet
*.csv

# Credenciales
.kaggle/
*.json
EOF

git add extract/queries.sql .gitignore \
        extract/csv_to_parquet.py extract/load_to_bigquery.py 2>/dev/null
git commit -m "Manual 01: ingesta ELT (PaySim + CFPB) a Data Lake + BigQuery + SQL de fraude"
git push origin main
```

### ✅ Checkpoint 11
En GitHub aparecen `queries.sql` (y los scripts opcionales), pero **NO** los datos crudos. 🎉

---

## 12. Checklist

- [ ] Transacciones (PaySim) y quejas (CFPB) descargadas.
- [ ] Bucket Data Lake creado con zonas `raw/staging/curated` (por UI o CLI).
- [ ] `transactions.csv` y `complaints_full.csv` subidos a `raw/`.
- [ ] Dataset `fraud_raw` creado en BigQuery.
- [ ] Tabla `transactions` con ~6.3M filas, snake_case y `hour_of_day`, ~0.13% de fraude verificado.
- [ ] Tabla `complaints` filtrada (con narrativa, temas de fraude).
- [ ] Las 10 consultas SQL de fraude ejecutan correctamente.
- [ ] (Opcional) Script `load_to_bigquery.py` reutilizable y probado.
- [ ] Commit en GitHub (sin datos crudos).

Si todo está ✅ → **listo para el Manual 02: Transformación ELT con dbt (features de fraude).**

---

## 13. Troubleshooting

| Problema | Causa | Solución |
|---|---|---|
| El botón **Download** de Kaggle pide verificación | Kaggle exige teléfono verificado | Verifica tu cuenta en Settings, o usa el mirror de CFPB oficial. |
| Subida por navegador muy lenta / se corta | Archivo de 470 MB | Usa Cloud Shell (`gcloud storage cp`), sube desde la red de Google. |
| `401 - Unauthorized` en Kaggle (CLI) | `kaggle.json` mal ubicado | `~/.kaggle/kaggle.json` con `chmod 600`. |
| Create table falla: "schema mismatch" en quejas | Tipos inconsistentes/comillas | Activa **Allow quoted newlines** y sube **Number of errors allowed** a 1000. |
| El filtro de quejas deja 0 filas | El mirror usa otros nombres de columna | Revisa el SCHEMA (Paso 8.2) y ajusta `Issue`/`Product`/narrativa. |
| "Not found: Dataset" al consultar | Región distinta entre bucket y dataset | Ambos deben estar en `us-central1`. |
| `pct_fraude` da 0 | La etiqueta se llamó distinto | Revisa el SCHEMA de `transactions`; ajusta `is_fraud`. |
| Cloud Shell "No space left" (camino CLI) | 5 GB llenos | Borra `.zip` y CSV crudos tras subir al lake. |

---

## 14. Glosario

- **Ingesta:** traer datos de una fuente a tu plataforma.
- **ETL vs ELT:** transformar *antes* de cargar (ETL, con Python) vs cargar crudo y transformar *dentro* del warehouse con SQL (ELT, cloud-native — el camino principal aquí).
- **Bucket / objeto:** contenedor / archivo en Cloud Storage.
- **Dataset (BigQuery):** agrupación de tablas (≈ esquema).
- **Autodetect:** BigQuery infiere el esquema (tipos y nombres) del archivo al cargarlo.
- **Parquet:** formato columnar comprimido, eficiente para analítica y gran volumen (variante avanzada).
- **Capa raw/staging/curated:** zonas del Data Lake (bronze/silver/gold).
- **Window function:** función SQL sobre un marco de filas (`OVER`, `PARTITION BY`) — clave para features de velocidad/temporales en fraude.
- **CTE (`WITH`):** subconsulta nombrada que mejora legibilidad.
- **Clases desbalanceadas:** cuando una clase (fraude) es rarísima frente a la otra; reto central del modelado de fraude.
- **Idempotente:** ejecutable varias veces con el mismo resultado final.
- **`is_fraud`:** etiqueta objetivo (1=fraude, 0=legítima) que el modelo aprenderá a predecir.

---

> **⬅️ Anterior:** [Manual 00 — Configuración del entorno](./00_configuracion_entorno_nube.md)
> **➡️ Siguiente:** Manual 02 — Transformación ELT con dbt (features de fraude) _(en construcción)_
