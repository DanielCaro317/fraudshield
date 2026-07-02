# Manual 03 — Orquestación con Airflow

> **Objetivo:** Automatizar TODO el pipeline de datos (ingesta → BigQuery → dbt → validación de calidad) con **Apache Airflow**, la herramienta de orquestación pedida explícitamente por Ceiba. Aprenderás Airflow de cero: DAGs, tasks, operadores, dependencias, scheduling, reintentos e idempotencia. Practicarás **gratis** (Airflow standalone) y verás cómo se lleva a **Cloud Composer** (Airflow gestionado en GCP) para el portafolio.
>
> **Tiempo estimado:** 5–7 horas.
> **Prerrequisito:** Manuales 01 y 02 completos (datos en BigQuery + proyecto dbt funcionando).
> **Cubre del cargo:** **Airflow**, automatización de procesos de datos, scripting (Ceiba).
> **Nube:** GCP. Incluye 🔁 callout de AWS (MWAA).

---

## 📋 Tabla de contenido

1. [Conceptos previos](#1-conceptos-previos)
2. [¿Por qué Airflow y no un cron?](#2-por-que-airflow)
3. [Dónde correremos Airflow (decisión de entorno)](#3-entorno)
4. [Instalar Airflow (standalone, gratis)](#4-instalar)
5. [Arrancar Airflow y entrar a la UI](#5-arrancar)
6. [Anatomía de un DAG](#6-anatomia)
7. [Construir el DAG del pipeline de fraude](#7-dag)
8. [Ejecutar y monitorear el DAG](#8-ejecutar)
9. [Scheduling, reintentos e idempotencia](#9-scheduling)
10. [Llevarlo a producción: Cloud Composer (demo)](#10-composer)
11. [Commit a GitHub](#11-commit)
12. [✅ Checklist final](#12-checklist)
13. [🛟 Solución de problemas](#13-troubleshooting)
14. [📖 Glosario](#14-glosario)

---

## 1. Conceptos previos

📖 **Orquestación:** coordinar automáticamente varias tareas en el orden correcto, con horarios, dependencias, reintentos y monitoreo. Es el "director de orquesta" de tu pipeline.

📖 **Apache Airflow:** la herramienta estándar para orquestar pipelines de datos. Defines tus flujos como **código Python**.

📖 **DAG (Directed Acyclic Graph):** un "flujo de trabajo". Es un grafo de **tasks** (tareas) conectadas por **dependencias**, sin ciclos (no puede volver atrás). Ej.: `ingesta → transformar → validar`.

📖 **Task (tarea):** una unidad de trabajo dentro del DAG (ej. "cargar a BigQuery").

📖 **Operator (operador):** la *plantilla* que define qué hace una task:
- `BashOperator` → ejecuta un comando de shell.
- `PythonOperator` → ejecuta una función de Python.
- (Existen operadores específicos: `BigQueryInsertJobOperator`, etc.)

📖 **Scheduler:** el componente que decide cuándo correr cada DAG según su horario.

📖 **Idempotencia:** que correr una task varias veces produzca el mismo resultado (sin duplicar datos). Es **fundamental** en orquestación.

💡 **El flujo que orquestarás:** `extract_load` (GCS → BigQuery) → `dbt_build` (transformar + testear) → `data_quality_check` (validar que hay datos y fraude). Lo que hiciste a mano en los Manuales 01 y 02, ahora **automático y programado**.

---

## 2. Por que Airflow

Te lo van a preguntar. La respuesta:
- **Un cron** (tarea programada simple) solo ejecuta comandos a una hora; no sabe de **dependencias** ("no transformes si la ingesta falló"), **reintentos**, **visibilidad** ni **historial**.
- **Airflow** da: dependencias explícitas, **reintentos automáticos**, **UI** para ver qué corrió/falló y por qué, **logs por task**, **backfill** (re-ejecutar fechas pasadas), alertas, y todo **como código versionado**.

🔁 **En AWS:** el equivalente gestionado es **MWAA (Managed Workflows for Apache Airflow)** — mismo Airflow, misma habilidad. También existe **Step Functions** (orquestador nativo de AWS). Por eso aprender Airflow es portable.

---

## 3. Entorno

Airflow es **pesado** (scheduler + webserver + base de datos). Tienes 3 opciones; elegimos por costo y simplicidad:

| Opción | Costo | Cuándo |
|---|---|---|
| **A. Airflow standalone en Cloud Shell** ⭐ | **Gratis** | **Para aprender** (lo usaremos). Ya tienes auth de GCP y dbt aquí. |
| B. Airflow en Docker en tu PC local | Gratis | Si Cloud Shell se queda corto de memoria; tu PC (64 GB) lo corre sobrado. |
| C. Cloud Composer (Airflow gestionado) | 💲 ~USD 0.50/h (NO free tier) | **Solo demo final** para el portafolio (§10). Se apaga al terminar. |

> ⭐ **Decisión:** aprendemos con la **Opción A (gratis)**. Hacemos una **demo corta** en Composer (Opción C) solo para tener la captura "lo desplegué en GCP gestionado" y la apagamos enseguida.

💡 **Por qué no Composer para aprender:** cobra por hora **aunque no lo uses**; dejarlo encendido una semana cuesta ~USD 80. No tiene sentido para practicar.

---

## 4. Instalar

> Trabajaremos en **Cloud Shell**. Recuerda: tu `$HOME` persiste, así que Airflow seguirá ahí entre sesiones.

### Paso 4.1 — Definir AIRFLOW_HOME
```bash
export AIRFLOW_HOME=~/airflow
echo 'export AIRFLOW_HOME=~/airflow' >> ~/.bashrc
```

### Paso 4.2 — Instalar Airflow con el archivo de restricciones (constraints)
Airflow exige instalar con un archivo de "constraints" para evitar conflictos de versiones:
```bash
AIRFLOW_VERSION=2.9.3
PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

pip install --user "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"
```
Tardará 2–4 min. 💡 El `--constraint` fija versiones compatibles de las ~100 dependencias de Airflow.

### Paso 4.3 — Verificar
```bash
export PATH=$HOME/.local/bin:$PATH
airflow version
```
Debe imprimir `2.9.3`. 

💡 Añade el PATH a tu `.bashrc` para no repetirlo:
```bash
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
```

### Paso 4.4 — Apuntar Airflow a la carpeta de DAGs del repo y ocultar ejemplos
Queremos que Airflow lea los DAGs desde `~/fraudshield/dags` (tu repo) y no nos llene la UI con DAGs de ejemplo:
```bash
echo 'export AIRFLOW__CORE__DAGS_FOLDER=$HOME/fraudshield/dags' >> ~/.bashrc
echo 'export AIRFLOW__CORE__LOAD_EXAMPLES=False' >> ~/.bashrc
source ~/.bashrc
```

### ✅ Checkpoint 4
`airflow version` → `2.9.3`. Las variables `AIRFLOW_HOME`, `AIRFLOW__CORE__DAGS_FOLDER` y `AIRFLOW__CORE__LOAD_EXAMPLES` están exportadas (verifica con `env | grep AIRFLOW`).

---

## 5. Arrancar

### Paso 5.1 — Iniciar Airflow en modo standalone
`airflow standalone` inicializa la base de datos, crea un usuario admin y arranca scheduler + webserver, todo en un comando:
```bash
airflow standalone
```
La primera vez tarda ~1 min. Cuando esté listo verás en los logs algo como:
```
standalone | Airflow is ready
standalone | Login with username: admin  password: <UNA_CONTRASEÑA>
```
📌 **Copia esa contraseña.** También queda guardada en `~/airflow/standalone_admin_password.txt`.

⚠️ **Este comando ocupa la terminal** (queda corriendo). No la cierres. Para ejecutar otros comandos, abre **otra pestaña de Cloud Shell** con el botón **"+"**.

### Paso 5.2 — Abrir la UI de Airflow (Web Preview)
1. En la barra de Cloud Shell, clic en **"Web Preview"** (ícono de pantalla con ojo) → **"Preview on port 8080"**.
2. Se abre la UI de Airflow. Inicia sesión con **admin** y la contraseña del paso 5.1.

### ✅ Checkpoint 5
Ves la interfaz de Airflow en el navegador, sin DAGs de ejemplo (solo aparecerá el nuestro cuando lo creemos). 

🛟 *Si la UI no abre o va muy lenta / se cae:* Cloud Shell tiene poca RAM. Mira la sección 🛟 (opción de correr en tu PC local). *Si pide otra ruta de puerto:* usa "Change port" → 8080.

---

## 6. Anatomia

Antes de escribir el DAG, entiende sus partes. Un DAG tiene:
1. **Imports** (Airflow y operadores).
2. **`default_args`**: configuración común para todas las tasks (reintentos, etc.).
3. **El objeto `DAG`**: id, horario (`schedule`), fecha de inicio, etc.
4. **Las tasks** (instancias de operadores).
5. **Las dependencias** (`tarea_a >> tarea_b` = "b depende de a").

💡 **Regla mental:** `A >> B` significa "primero A, luego B".

---

## 7. Dag

Vamos a crear el DAG que orquesta tu pipeline completo.

### Paso 7.1 — Crear el archivo del DAG
Crea `~/fraudshield/dags/fraud_pipeline.py`. Usa el editor (Open Editor) o este comando (en la **segunda pestaña** de Cloud Shell):
```bash
cat > ~/fraudshield/dags/fraud_pipeline.py << 'EOF'
"""
DAG FraudShield: orquesta el pipeline de datos antifraude.
  extract_load  -> carga datos de Cloud Storage a BigQuery (Manual 01)
  dbt_build     -> transforma y testea con dbt (Manual 02)
  data_quality  -> valida que existan datos y casos de fraude
"""
import os
import subprocess
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

HOME = os.path.expanduser("~")

# Configuración común a todas las tasks
default_args = {
    "owner": "daniel",
    "retries": 2,                          # reintenta 2 veces si falla
    "retry_delay": timedelta(minutes=2),   # espera 2 min entre reintentos
}


def validar_calidad(**context):
    """Falla el pipeline si no hay datos o no hay casos de fraude."""
    consulta = (
        "SELECT COUNT(*) AS n "
        "FROM `fraud_dbt.mart_fraud_features` "
        "WHERE is_fraud = 1"
    )
    # bash -lc carga el perfil para que 'bq' esté en el PATH
    cmd = f'bq query --use_legacy_sql=false --format=csv "{consulta}"'
    res = subprocess.run(["bash", "-lc", cmd], capture_output=True, text=True)
    if res.returncode != 0:
        raise RuntimeError(f"Error consultando BigQuery: {res.stderr}")
    # La salida CSV es: encabezado 'n' y luego el número
    fraudes = int(res.stdout.strip().splitlines()[-1])
    print(f"Casos de fraude encontrados: {fraudes:,}")
    if fraudes == 0:
        raise ValueError("¡Validación fallida! No hay casos de fraude en el mart.")
    print("Validación de calidad: OK ✅")


with DAG(
    dag_id="fraud_pipeline",
    description="Pipeline ELT antifraude de FraudShield",
    default_args=default_args,
    start_date=datetime(2024, 1, 1),
    schedule="@daily",        # corre una vez al día
    catchup=False,            # no re-ejecutar fechas pasadas
    tags=["fraudshield", "elt"],
) as dag:

    # Task 1: cargar de Cloud Storage a BigQuery (idempotente, usa --replace)
    extract_load = BashOperator(
        task_id="extract_load_to_bigquery",
        bash_command=(
            "export PATH=$HOME/.local/bin:$PATH; "
            "python3 $HOME/fraudshield/extract/load_to_bigquery.py"
        ),
    )

    # Task 2: transformar y testear con dbt
    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command=(
            "export PATH=$HOME/.local/bin:$PATH; "
            "cd $HOME/fraudshield/dbt_project && dbt build"
        ),
    )

    # Task 3: validar calidad de los datos resultantes
    data_quality = PythonOperator(
        task_id="data_quality_check",
        python_callable=validar_calidad,
    )

    # Dependencias: 1 -> 2 -> 3
    extract_load >> dbt_build >> data_quality
EOF
```

### Paso 7.2 — Que Airflow detecte el DAG
Airflow escanea la carpeta de DAGs cada ~30 s. Refresca la UI; debe aparecer **`fraud_pipeline`**. Si no, en la segunda pestaña corre:
```bash
airflow dags list
```
Debe listar `fraud_pipeline`.

🛟 *Si no aparece o hay error de importación:* revisa errores con `airflow dags list-import-errors`. Suele ser una indentación o un import mal escrito.

### ✅ Checkpoint 7
`fraud_pipeline` aparece en la UI de Airflow (y en `airflow dags list`).

---

## 8. Ejecutar

### Paso 8.1 — Activar y disparar el DAG
1. En la UI, busca `fraud_pipeline`.
2. Activa el **toggle** (interruptor) a la izquierda del nombre para "despausarlo".
3. Clic en el botón **▶ (Trigger DAG)** a la derecha para ejecutarlo manualmente ahora.

### Paso 8.2 — Ver el progreso
1. Clic en el nombre `fraud_pipeline` → vista **"Grid"** (cuadrícula).
2. Verás las 3 tasks ejecutándose: verde = éxito, amarillo = corriendo, rojo = falló.
3. Clic en cualquier cuadro de task → **"Logs"** para ver su salida detallada.

💡 Orden esperado: `extract_load_to_bigquery` (1–3 min) → `dbt_build` (1–2 min) → `data_quality_check` (segundos, imprime "Casos de fraude encontrados: ...").

### Paso 8.3 — Ver el grafo
Clic en la pestaña **"Graph"**: verás el flujo `extract_load → dbt_build → data_quality`. Esto es tu pipeline orquestado. 🎉

### ✅ Checkpoint 8
Las 3 tasks terminan en **verde**. En los logs de `data_quality_check` ves "Validación de calidad: OK ✅".

🛟 *Si `dbt_build` falla con "dbt: command not found":* el PATH no incluyó `~/.local/bin`. Ya lo añadimos en el `bash_command`, pero verifica que dbt esté instalado (`which dbt`). *Si falla por auth de BigQuery:* asegúrate de haber hecho `gcloud auth application-default login` (Manual 02).

---

## 9. Scheduling

Conceptos senior que debes poder explicar:

### Scheduling (programación)
- `schedule="@daily"` → corre cada día a medianoche. Otras opciones: `"@hourly"`, `"@weekly"`, o **cron** (`"0 6 * * *"` = 6 AM diario).
- `start_date` → desde cuándo "existe" el DAG.
- `catchup=False` → **no** re-ejecuta todas las fechas desde `start_date` (si fuera `True`, intentaría "ponerse al día" con cada día perdido — útil para backfills, peligroso si no lo esperas).

### Reintentos (retries)
- `retries=2` + `retry_delay` → si una task falla (ej. error de red), Airflow la reintenta automáticamente antes de marcarla como fallida. Imprescindible en producción.

### Idempotencia
- Nuestro `extract_load` usa `bq load --replace` y `dbt build` reconstruye → correr el DAG 2 veces deja el **mismo** resultado, no duplica datos. **Eso es idempotencia.** 💡 En entrevista: "diseño tasks idempotentes para poder reintentar sin efectos secundarios".

### Backfill (mencionar)
- Re-ejecutar el pipeline para un rango de fechas pasadas: `airflow dags backfill ...`. Útil cuando llegan datos históricos.

### ✅ Checkpoint 9
Puedes explicar con tus palabras: schedule, catchup, retries e idempotencia.

---

## 10. Composer

> 💲 **Opcional pero recomendado para el portafolio.** Cloud Composer es Airflow **gestionado** por GCP: Google administra los servidores. Lo usamos para una **demo corta** y lo **apagamos** enseguida (cobra por hora). Si quieres ahorrar 100%, salta esta sección y describe Composer conceptualmente en tu portafolio.

### 10.1 — Qué es y por qué importa
- Composer = Airflow sin que tú administres infraestructura. En empresas reales casi nadie corre Airflow "a mano"; usan Composer (GCP) o **MWAA** (AWS).
- Tus DAGs viven en un **bucket de Cloud Storage** que Composer vigila; subes el `.py` y aparece en la UI.

### 10.2 — Crear un entorno (toma ~25 min)
```bash
gcloud composer environments create fraudshield-demo \
  --location us-central1 \
  --image-version composer-3-airflow-2 \
  --environment-size small
```
💡 Mientras se crea, ten claro que **a partir de aquí corre el reloj de costos**.

### 10.3 — Subir el DAG
Cuando el entorno esté `RUNNING`, sube tu DAG a su carpeta:
```bash
gcloud composer environments storage dags import \
  --environment fraudshield-demo \
  --location us-central1 \
  --source ~/fraudshield/dags/fraud_pipeline.py
```

### 10.4 — Abrir la UI de Composer
```bash
gcloud composer environments describe fraudshield-demo \
  --location us-central1 --format="value(config.airflowUri)"
```
Abre esa URL → es la UI de Airflow gestionada. Toma tu **captura para el portafolio** (DAG corriendo en Composer). 📸

### 10.5 — ⚠️ APAGAR el entorno (NO lo olvides)
```bash
gcloud composer environments delete fraudshield-demo --location us-central1
```
Confirma con `Y`. Verifica que ya no existe:
```bash
gcloud composer environments list --locations us-central1
```

🔁 **En AWS:** el equivalente es **MWAA**; subes los DAGs a un bucket S3 y AWS administra el Airflow. Mismo concepto, misma habilidad.

### ✅ Checkpoint 10 (si hiciste la demo)
Tienes una captura del DAG en Composer **y confirmaste que el entorno fue eliminado** (sin costos colgando).

---

## 11. Commit

```bash
cd ~/fraudshield
git add dags/fraud_pipeline.py
git commit -m "Manual 03: DAG de Airflow que orquesta ingesta -> dbt -> validacion de calidad"
git push origin main
```

💡 Añade los artefactos locales de Airflow al `.gitignore` (no queremos subir la BD ni logs de Airflow, que viven en `~/airflow`, fuera del repo — así que normalmente no hay nada que ignorar, pero por si copiaste algo):
```bash
cd ~/fraudshield
printf '\n# Airflow (artefactos locales)\nairflow.db\nairflow.cfg\nlogs/\nstandalone_admin_password.txt\n' >> .gitignore
git add .gitignore && git commit -m "Ignorar artefactos locales de Airflow" && git push origin main
```

### ✅ Checkpoint 11
En GitHub aparece `dags/fraud_pipeline.py`.

---

## 12. Checklist

- [ ] Airflow 2.9.3 instalado en Cloud Shell.
- [ ] `AIRFLOW_HOME` y carpeta de DAGs apuntando al repo configurados.
- [ ] `airflow standalone` arranca y entro a la UI (puerto 8080).
- [ ] DAG `fraud_pipeline` visible en la UI.
- [ ] Las 3 tasks (`extract_load → dbt_build → data_quality`) corren en verde.
- [ ] Entiendo schedule, catchup, retries e idempotencia.
- [ ] (Opcional) Demo en Cloud Composer + **entorno eliminado**.
- [ ] DAG commiteado en GitHub.

Si todo está ✅ → **listo para el Manual 04: Modelado de ML (detección de fraude).**

---

## 13. Troubleshooting

| Problema | Causa | Solución |
|---|---|---|
| UI lenta o Cloud Shell se cuelga | Airflow consume RAM y Cloud Shell tiene poca | Cierra otras pestañas; reinicia Cloud Shell; o corre Airflow en tu **PC local** (64 GB) con `pip install apache-airflow` y `airflow standalone` (necesitarás `gcloud` y `dbt` locales autenticados). |
| `airflow: command not found` | PATH | `export PATH=$HOME/.local/bin:$PATH`. |
| DAG no aparece | Error de import o carpeta equivocada | `airflow dags list-import-errors`; confirma `AIRFLOW__CORE__DAGS_FOLDER`. |
| `dbt build` falla en la task | PATH o auth | El `bash_command` ya exporta el PATH; verifica `gcloud auth application-default login`. |
| `data_quality_check` falla por `bq` | PATH del subproceso | Usamos `bash -lc` para cargar el PATH; si persiste, usa la ruta completa de `bq`. |
| Olvidé la contraseña admin | — | Está en `~/airflow/standalone_admin_password.txt`. |
| Composer tarda/cuesta | Es normal (~25 min y cobra) | Haz la demo rápida y **elimínalo** (paso 10.5). |
| `standalone` se detuvo al cerrar la pestaña | Corre en primer plano | Vuelve a ejecutar `airflow standalone`; tu BD y DAGs persisten. |

---

## 14. Glosario

- **Orquestación:** coordinar tareas en orden, con horarios, dependencias y reintentos.
- **Airflow:** orquestador de pipelines definido en Python.
- **DAG:** grafo dirigido acíclico = un flujo de trabajo.
- **Task:** una tarea del DAG.
- **Operator:** plantilla de task (`BashOperator`, `PythonOperator`...).
- **Scheduler:** componente que decide cuándo correr.
- **`>>`:** define dependencia ("A antes que B").
- **schedule / catchup / retries:** horario / ponerse al día / reintentos.
- **Idempotencia:** correr varias veces = mismo resultado.
- **Backfill:** re-ejecutar fechas pasadas.
- **Cloud Composer / MWAA:** Airflow gestionado en GCP / AWS.

---

> **⬅️ Anterior:** [Manual 02 — Transformación ELT con dbt](./02_transformacion_elt_dbt.md)
> **➡️ Siguiente:** Manual 04 — Modelado de ML (detección de fraude) _(en construcción)_
