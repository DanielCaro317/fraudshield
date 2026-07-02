# Manual 01 — Ingesta de datos y Data Lake

> **Objetivo:** Traer los datos del caso de fraude bancario (transacciones masivas + narrativas cualitativas de quejas de clientes) desde fuentes públicas, almacenarlos en un **Data Lake** (Cloud Storage) y cargarlos en un **Data Warehouse** (BigQuery), dejándolos listos para consultar con SQL. Aprenderás ingesta, organización de un Data Lake por capas y manejo de gran volumen — sobre un caso real de detección de fraude.
>
> **Tiempo estimado:** 4–6 horas.
> **Prerrequisito:** Manual 00 completo (entorno cloud listo, repo `fraudshield` clonado).
> **Requisitos del cargo que cubre:** prospección de fuentes (datos estructurados y no estructurados), gran volumen, SQL relacional, fundamentos de Data Engineering.

---

## 📋 Tabla de contenido

1. [Conceptos previos](#1-conceptos-previos)
2. [El caso de negocio y los datasets](#2-datasets)
3. [Obtener tus credenciales de Kaggle](#3-kaggle-creds)
4. [Descargar los datasets en Cloud Shell](#4-descargar)
5. [Crear el Data Lake (Cloud Storage)](#5-data-lake)
6. [Preparar y subir los datos al Data Lake](#6-subir)
7. [Crear el Data Warehouse (BigQuery)](#7-bigquery)
8. [Cargar las transacciones a BigQuery](#8-cargar)
9. [Cargar las quejas (datos no estructurados) a BigQuery](#9-no-estructurados)
10. [Tus primeras 10 consultas SQL de fraude](#10-sql)
11. [Automatizar la ingesta con un script Python](#11-script)
12. [Commit a GitHub](#12-commit)
13. [✅ Checklist final](#13-checklist)
14. [🛟 Solución de problemas](#14-troubleshooting)
15. [📖 Glosario](#15-glosario)

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

📖 **Datos estructurados vs no estructurados (clave para el cargo):**
- **Estructurados:** filas y columnas con tipos definidos → las **transacciones** (monto, tipo, cuentas, etiqueta de fraude).
- **No estructurados:** texto libre sin esquema fijo → las **narrativas de quejas** de clientes. Aquí harás, más adelante, **consultas semánticas y cualitativas** (Manual 05, RAG).

💡 **El flujo de este manual:** Kaggle/CFPB → descargar a Cloud Shell → subir a Cloud Storage (`raw/`) → cargar a BigQuery → consultar con SQL.

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
- En Kaggle búscalo como **"consumer complaint database"** (varios mirrors). Fuente oficial: `https://www.consumerfinance.gov/data-research/consumer-complaints/`
- 💡 Es un dataset grande; en el Paso 4 filtramos solo las quejas **con narrativa** y de categorías de fraude para no saturar Cloud Shell.

> **Nota:** Los slugs de Kaggle a veces cambian. En el Paso 4 te muestro cómo copiar el comando de descarga exacto desde la página del dataset.

---

## 3. Kaggle creds

Para descargar datasets por terminal necesitas una API key de Kaggle.

### Paso 3.1 — Crear cuenta en Kaggle
Ve a **https://www.kaggle.com/** → **Register**. Verifica tu correo y número (Kaggle pide verificación por teléfono para descargas vía API).

### Paso 3.2 — Generar el token de API
1. Inicia sesión en Kaggle.
2. Clic en tu **foto de perfil** (arriba derecha) → **Settings**.
3. Baja a la sección **"API"** → clic en **"Create New Token"**.
4. Se descarga un archivo **`kaggle.json`** a tu PC con `{"username":"...","key":"..."}`. **No lo compartas.**

### Paso 3.3 — Subir kaggle.json a Cloud Shell
1. Abre **Cloud Shell** en la consola de GCP.
2. En la barra de Cloud Shell, clic en el menú **⋮ (tres puntos)** → **Upload** → selecciona tu `kaggle.json`. Se sube a tu `$HOME` (`~`).
3. Mueve el archivo a donde Kaggle lo espera y protégelo:
```bash
mkdir -p ~/.kaggle
mv ~/kaggle.json ~/.kaggle/kaggle.json
chmod 600 ~/.kaggle/kaggle.json
```

### Paso 3.4 — Instalar la librería de Kaggle
```bash
pip install --user kaggle
```
💡 El `--user` instala en tu home (persiste). Si `kaggle` no se encuentra luego, usa `python3 -m kaggle`.

### ✅ Checkpoint 3
```bash
kaggle datasets list -s "fraud detection" --max-size 1000
```
Debe listar datasets (si ves una tabla con nombres, la autenticación funciona).

🛟 *Si dice "401 Unauthorized":* el `kaggle.json` está mal ubicado o sin permisos → repite el paso 3.3. *Si dice "command not found":* usa `python3 -m kaggle ...`.

---

## 4. Descargar

### Paso 4.1 — Crear carpeta de trabajo
```bash
cd ~/fraudshield/extract
mkdir -p data/transactions data/complaints
```

### Paso 4.2 — Descargar el dataset de transacciones (PaySim)
```bash
cd ~/fraudshield/extract/data/transactions
kaggle datasets download -d ealaxi/paysim1
unzip -q paysim1.zip
ls -lh
```
Verás el CSV grande (~470 MB). 

💡 **Cómo obtener el comando exacto si el slug cambió:** entra a la página del dataset en Kaggle → botón **⋮** / "Download" → **"Copy API command"** y pégalo aquí.

### Paso 4.3 — Renombrar el CSV (para simplificar)
El nombre original es largo. Renómbralo:
```bash
mv PS_*.csv transactions.csv
ls -lh transactions.csv
```

### Paso 4.4 — Descargar el dataset de quejas (CFPB)
```bash
cd ~/fraudshield/extract/data/complaints
# Ejemplo de slug (verifica el actual en Kaggle):
kaggle datasets download -d selener/consumer-complaint-database
unzip -q consumer-complaint-database.zip
ls -lh
```
Verás un CSV grande de quejas. Renómbralo:
```bash
mv *.csv complaints_full.csv 2>/dev/null; ls -lh
```

### Paso 4.5 — Liberar espacio (importante)
Cloud Shell solo tiene 5 GB. Borra los `.zip` ya descomprimidos:
```bash
rm -f ~/fraudshield/extract/data/**/*.zip
df -h ~ | tail -1   # revisa el espacio disponible
```

### ✅ Checkpoint 4
- `data/transactions/transactions.csv` existe (~470 MB).
- `data/complaints/complaints_full.csv` existe.
- Tienes espacio libre en disco (`df -h`).

---

## 5. Data Lake

### Paso 5.1 — Definir un nombre único de bucket
El nombre del bucket debe ser **único en todo el mundo**. Usa tu Project ID como prefijo:
```bash
export PROJECT_ID=$(gcloud config get-value project)
export BUCKET="gs://${PROJECT_ID}-datalake"
echo "Mi bucket será: $BUCKET"
```

### Paso 5.2 — Crear el bucket
```bash
gcloud storage buckets create $BUCKET \
  --location=us-central1 \
  --uniform-bucket-level-access
```
Salida esperada: `Creating gs://...-datalake/...`

💡 `--location=us-central1` lo pone en la misma región que BigQuery (evita costos de transferencia). `--uniform-bucket-level-access` simplifica permisos.

### Paso 5.3 — Crear las zonas del Data Lake
```bash
echo "raw zone"     | gcloud storage cp - $BUCKET/raw/.keep
echo "staging zone" | gcloud storage cp - $BUCKET/staging/.keep
echo "curated zone" | gcloud storage cp - $BUCKET/curated/.keep
```

### ✅ Checkpoint 5
```bash
gcloud storage ls $BUCKET
```
Debe listar `raw/`, `staging/`, `curated/`. También visible en la consola: **Cloud Storage → Buckets**.

---

## 6. Subir

### 6.1 — Transacciones: convertir CSV → Parquet (eficiencia y gran volumen)

📖 **Parquet** pesa ~5–10x menos que CSV y BigQuery lo carga más rápido. Como el CSV es grande (6.3M filas), lo convertimos **por trozos (chunks)** para no agotar la memoria de Cloud Shell.

Crea el script. Usa el editor (Open Editor) o este comando:
```bash
cat > ~/fraudshield/extract/csv_to_parquet.py << 'EOF'
"""
Convierte el CSV grande de PaySim a Parquet por trozos (chunks),
normaliza nombres de columnas y añade columnas de control.
"""
import os
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

IN = os.path.expanduser("~/fraudshield/extract/data/transactions/transactions.csv")
OUT = os.path.expanduser("~/fraudshield/extract/data/transactions/transactions.parquet")

# Mapeo de columnas originales -> nombres limpios (snake_case)
RENAME = {
    "step": "step",
    "type": "type",
    "amount": "amount",
    "nameOrig": "name_orig",
    "oldbalanceOrg": "old_balance_orig",
    "newbalanceOrig": "new_balance_orig",
    "nameDest": "name_dest",
    "oldbalanceDest": "old_balance_dest",
    "newbalanceDest": "new_balance_dest",
    "isFraud": "is_fraud",
    "isFlaggedFraud": "is_flagged_fraud",
}

writer = None
total = 0
for chunk in pd.read_csv(IN, chunksize=500_000):
    chunk = chunk.rename(columns=RENAME)
    # columna derivada simple: hora del día (step % 24)
    chunk["hour_of_day"] = chunk["step"] % 24
    table = pa.Table.from_pandas(chunk, preserve_index=False)
    if writer is None:
        writer = pq.ParquetWriter(OUT, table.schema)
    writer.write_table(table)
    total += len(chunk)
    print(f"  procesadas {total:,} filas...")

if writer:
    writer.close()
print(f"Listo: {OUT} ({total:,} filas)")
EOF
```

Instala dependencias y ejecuta:
```bash
pip install --user pandas pyarrow
cd ~/fraudshield/extract
python3 csv_to_parquet.py
```
Verás el conteo subir hasta ~6.3M filas y al final `Listo: ...transactions.parquet`.

### 6.2 — Quejas: filtrar solo las relevantes (con narrativa y de fraude)

El CSV de CFPB es enorme y muchas filas no tienen narrativa. Filtramos las útiles para fraude y texto. Crea:
```bash
cat > ~/fraudshield/extract/filter_complaints.py << 'EOF'
"""
Filtra las quejas CFPB: solo las que tienen narrativa de texto y
pertenecen a categorías relacionadas con fraude/estafa/cargos no autorizados.
Guarda un CSV liviano listo para BigQuery.
"""
import os
import pandas as pd

IN = os.path.expanduser("~/fraudshield/extract/data/complaints/complaints_full.csv")
OUT = os.path.expanduser("~/fraudshield/extract/data/complaints/complaints_fraud.csv")

# Palabras clave de fraude en el campo 'Issue' o 'Product'
KEYWORDS = ["fraud", "scam", "unauthorized", "identity theft", "stolen"]

frames = []
total = 0
kept = 0
for chunk in pd.read_csv(IN, chunksize=200_000, low_memory=False):
    total += len(chunk)
    # normalizar nombres de columnas
    chunk.columns = [c.strip().lower().replace(" ", "_").replace("-", "_") for c in chunk.columns]
    # detectar la columna de narrativa
    narr_col = next((c for c in chunk.columns if "narrative" in c), None)
    if narr_col is None:
        continue
    # quedarnos solo con filas que tienen texto
    sub = chunk[chunk[narr_col].notna()].copy()
    # filtrar por palabras clave de fraude en issue/product
    text_cols = [c for c in sub.columns if c in ("issue", "product", "sub_issue")]
    if text_cols:
        mask = False
        for c in text_cols:
            col = sub[c].astype(str).str.lower()
            for kw in KEYWORDS:
                mask = mask | col.str.contains(kw, na=False)
        sub = sub[mask]
    frames.append(sub)
    kept += len(sub)
    print(f"  revisadas {total:,} / conservadas {kept:,}")

result = pd.concat(frames, ignore_index=True)
# Limitar a 50k para mantenerlo liviano (suficiente para RAG y análisis)
result = result.head(50_000)
result.to_csv(OUT, index=False)
print(f"Listo: {OUT} ({len(result):,} quejas de fraude con narrativa)")
EOF

cd ~/fraudshield/extract
python3 filter_complaints.py
```
💡 Si tu CSV de CFPB no tiene columna "narrative", revisa los nombres con `head -1 complaints_full.csv` y ajusta el filtro. Algunos mirrors ya vienen filtrados con narrativa.

### 6.3 — Subir todo a la zona `raw/` del Data Lake
```bash
# Transacciones (Parquet)
gcloud storage cp ~/fraudshield/extract/data/transactions/transactions.parquet \
  $BUCKET/raw/transactions/

# Quejas (CSV filtrado)
gcloud storage cp ~/fraudshield/extract/data/complaints/complaints_fraud.csv \
  $BUCKET/raw/complaints/
```

### ✅ Checkpoint 6
```bash
gcloud storage ls -r $BUCKET/raw/
gcloud storage du -s $BUCKET/raw/
```
Debe mostrar el `.parquet` en `raw/transactions/` y el `.csv` en `raw/complaints/`.

---

## 7. BigQuery

### Paso 7.1 — Crear el dataset (la "carpeta" de tablas)
```bash
export PROJECT_ID=$(gcloud config get-value project)
bq --location=us-central1 mk --dataset \
  --description "Capa raw de FraudShield" \
  ${PROJECT_ID}:fraud_raw
```
Salida esperada: `Dataset '...:fraud_raw' successfully created.`

### ✅ Checkpoint 7
```bash
bq ls
```
Debe listar `fraud_raw`. En la consola: **BigQuery** → expande tu proyecto → verás `fraud_raw`.

---

## 8. Cargar

### Paso 8.1 — Cargar las transacciones (Parquet) a una tabla
BigQuery infiere el esquema desde Parquet:
```bash
bq load \
  --source_format=PARQUET \
  --replace \
  fraud_raw.transactions \
  "$BUCKET/raw/transactions/*.parquet"
```
Tardará 1–3 min. Salida esperada: `Current status: DONE`.

### Paso 8.2 — Verificar la carga y la distribución de fraude
```bash
bq query --use_legacy_sql=false \
'SELECT
   COUNT(*) AS filas,
   SUM(is_fraud) AS fraudes,
   ROUND(SUM(is_fraud)/COUNT(*)*100, 4) AS pct_fraude
 FROM `fraud_raw.transactions`'
```
Deberías ver **~6.36M filas**, ~8,213 fraudes y **~0.13% de fraude**. 🎯 (Ese desbalance es el reto del Manual 04.)

### Paso 8.3 — Inspeccionar esquema y muestra
```bash
bq show fraud_raw.transactions
bq query --use_legacy_sql=false \
'SELECT * FROM `fraud_raw.transactions` LIMIT 5'
```

### ✅ Checkpoint 8
La tabla `fraud_raw.transactions` existe con ~6.3M filas y la columna `is_fraud`.

---

## 9. No estructurados

Cargamos las quejas (texto libre) — la base de las consultas semánticas/cualitativas.

### Paso 9.1 — Cargar el CSV de quejas
```bash
bq load \
  --source_format=CSV \
  --autodetect \
  --skip_leading_rows=1 \
  --replace \
  --allow_quoted_newlines \
  fraud_raw.complaints \
  "$BUCKET/raw/complaints/*.csv"
```
💡 `--allow_quoted_newlines` es **clave** aquí: las narrativas tienen saltos de línea dentro del texto.

### Paso 9.2 — Verificar
```bash
bq query --use_legacy_sql=false \
'SELECT * FROM `fraud_raw.complaints` LIMIT 3'
```

🛟 *Si falla por formato:* añade `--max_bad_records=1000`. Revisa el separador con `head -1` (algunos usan `;` → añade `--field_delimiter=";"`).

### ✅ Checkpoint 9
La tabla `fraud_raw.complaints` existe y muestra narrativas de texto.

---

## 10. SQL

Practica SQL analítico **sobre el caso de fraude**. Ejecuta cada consulta y entiéndela (las window functions y CTEs son oro para entrevistas). Guárdalas luego en `queries.sql` (Paso 10.12).

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
  COUNTIF(LOWER(consumer_complaint_narrative) LIKE '%unauthorized%') AS no_autorizado,
  COUNTIF(LOWER(consumer_complaint_narrative) LIKE '%scam%') AS estafa,
  COUNTIF(LOWER(consumer_complaint_narrative) LIKE '%identity%') AS robo_identidad,
  COUNT(*) AS total_quejas
FROM `fraud_raw.complaints`;
```

> 💡 En la consulta 10, ajusta el nombre `consumer_complaint_narrative` al de tu tabla (revísalo con `bq show fraud_raw.complaints`). El autodetect convierte espacios a guiones bajos.

### Paso 10.12 — Guardar las consultas en el repo
Crea `~/fraudshield/extract/queries.sql` y pega las 10 consultas con sus comentarios (usa el editor "Open Editor" para pegar cómodo).

### ✅ Checkpoint 10
Las 10 consultas corren sin error (consola → BigQuery → pega y "Run", o `bq query`). Entiendes especialmente las **window functions** (5, 6) y la lógica de **inconsistencia de saldos** (7) — son argumentos potentes en entrevista para hablar de feature engineering de fraude.

---

## 11. Script

Empaquetamos la carga en un script reutilizable e idempotente (Airflow lo usará en el Manual 03).

```bash
cat > ~/fraudshield/extract/load_to_bigquery.py << 'EOF'
"""
Carga idempotente de Cloud Storage -> BigQuery para FraudShield.
Reutilizable por Airflow más adelante.
"""
import subprocess

PROJECT_ID = subprocess.check_output(
    ["gcloud", "config", "get-value", "project"], text=True).strip()
BUCKET = f"gs://{PROJECT_ID}-datalake"
DATASET = "fraud_raw"

def run(cmd):
    print(">", " ".join(cmd))
    subprocess.run(cmd, check=True)

def load_transactions():
    run([
        "bq", "load", "--source_format=PARQUET", "--replace",
        f"{DATASET}.transactions", f"{BUCKET}/raw/transactions/*.parquet",
    ])

def load_complaints():
    run([
        "bq", "load", "--source_format=CSV", "--autodetect",
        "--skip_leading_rows=1", "--replace", "--allow_quoted_newlines",
        f"{DATASET}.complaints", f"{BUCKET}/raw/complaints/*.csv",
    ])

if __name__ == "__main__":
    load_transactions()
    load_complaints()
    print("Ingesta de FraudShield completada.")
EOF

cd ~/fraudshield/extract
python3 load_to_bigquery.py
```

### ✅ Checkpoint 11
El script corre completo e imprime "Ingesta de FraudShield completada."

---

## 12. Commit

⚠️ **Nunca subas datos crudos ni credenciales a GitHub.**

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

git add extract/csv_to_parquet.py extract/filter_complaints.py \
        extract/load_to_bigquery.py extract/queries.sql .gitignore
git commit -m "Manual 01: ingesta de transacciones (PaySim) y quejas (CFPB) a Data Lake + Data Warehouse + SQL de fraude"
git push origin main
```

### ✅ Checkpoint 12
En GitHub aparecen los scripts y `queries.sql`, pero **NO** los datos crudos. 🎉

---

## 13. Checklist

- [ ] Credenciales de Kaggle funcionando en Cloud Shell.
- [ ] Transacciones (PaySim) y quejas (CFPB) descargadas.
- [ ] Bucket Data Lake creado con zonas `raw/staging/curated`.
- [ ] Transacciones convertidas a Parquet y subidas a `raw/transactions/`.
- [ ] Quejas filtradas (con narrativa, temas de fraude) subidas a `raw/complaints/`.
- [ ] Dataset `fraud_raw` creado en BigQuery.
- [ ] Tabla `transactions` con ~6.3M filas y ~0.13% de fraude verificado.
- [ ] Tabla `complaints` cargada con narrativas de texto.
- [ ] Las 10 consultas SQL de fraude ejecutan correctamente.
- [ ] Script `load_to_bigquery.py` reutilizable y probado.
- [ ] Commit en GitHub (sin datos crudos).

Si todo está ✅ → **listo para el Manual 02: Transformación ELT con dbt (features de fraude).**

---

## 14. Troubleshooting

| Problema | Causa | Solución |
|---|---|---|
| `kaggle: command not found` | No está en el PATH | Usa `python3 -m kaggle ...` o `export PATH=$PATH:~/.local/bin`. |
| `401 - Unauthorized` en Kaggle | `kaggle.json` mal ubicado | Repite paso 3.3; verifica `chmod 600`. |
| Cloud Shell sin espacio (`No space left`) | 5 GB llenos | Borra zips (`rm *.zip`) y los CSV crudos tras subir al lake. |
| `MemoryError` al convertir/filtrar | CSV muy grande para la RAM | Baja `chunksize` (ej. de 500_000 a 200_000). |
| `bq load` "schema mismatch" en quejas | Tipos inconsistentes/comillas | Añade `--max_bad_records=1000`; usa `--allow_quoted_newlines`. |
| La columna de narrativa no existe | El mirror de CFPB usa otros nombres | `head -1 complaints_full.csv` y ajusta el script de filtrado. |
| "Not found: Dataset" en BigQuery | Región distinta | Crea el dataset y consulta en `us-central1`. |
| El `pct_fraude` da 0 | La etiqueta se llamó distinto | Revisa `bq show fraud_raw.transactions`; ajusta `is_fraud`. |

---

## 15. Glosario

- **Ingesta:** traer datos de una fuente a tu plataforma.
- **Bucket / objeto:** contenedor / archivo en Cloud Storage.
- **Dataset (BigQuery):** agrupación de tablas (≈ esquema).
- **Parquet:** formato columnar comprimido, eficiente para analítica y gran volumen.
- **Chunk:** trozo del archivo procesado por partes para no agotar la memoria.
- **Capa raw/staging/curated:** zonas del Data Lake (bronze/silver/gold).
- **Window function:** función SQL sobre un marco de filas (`OVER`, `PARTITION BY`) — clave para features de velocidad/temporales en fraude.
- **CTE (`WITH`):** subconsulta nombrada que mejora legibilidad.
- **Clases desbalanceadas:** cuando una clase (fraude) es rarísima frente a la otra; reto central del modelado de fraude.
- **Idempotente:** ejecutable varias veces con el mismo resultado final.
- **`is_fraud`:** etiqueta objetivo (1=fraude, 0=legítima) que el modelo aprenderá a predecir.

---

> **⬅️ Anterior:** [Manual 00 — Configuración del entorno](./00_configuracion_entorno_nube.md)
> **➡️ Siguiente:** Manual 02 — Transformación ELT con dbt (features de fraude) _(en construcción)_
