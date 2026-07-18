# Manual 02 — Transformación ELT con dbt (features de fraude)

> **Objetivo:** Transformar los datos crudos de BigQuery en **features de fraude limpias y modeladas** usando **dbt** (la herramienta estándar de la "T" en ELT, pedida explícitamente por Ceiba). Aprenderás dbt de cero: modelos por capas (staging → intermediate → marts), tests de calidad declarativos, documentación y lineage. Al final tendrás una tabla `mart_fraud_features` lista para entrenar el modelo (Manual 04).
>
> **Tiempo estimado:** 5–7 horas.
> **Prerrequisito:** Manual 01 completo (tablas `fraud_raw.transactions` y `fraud_raw.complaints` en BigQuery).
> **Cubre del cargo:** ETL/**ELT**, **dbt**, SQL, **calidad de datos** (Ceiba) · feature engineering reproducible (base para Proxify).
> **Nube:** GCP (BigQuery). Incluye 🔁 callouts de cómo sería en AWS.

---

## 🖱️ / ⌨️ Cómo leer este manual (una nota honesta sobre dbt)

**dbt es una herramienta de código, no de clics.** No existe un botón "crear modelo": un modelo *es* un archivo `.sql`. Aun así, puedes trabajarlo de forma **mucho más visual** de lo que parece, y así lo enfocamos aquí:

- 🖱️ **Por la UI:** creas y editas los archivos con el **editor gráfico** de Cloud Shell (**"Open Editor"**, idéntico a VS Code) — clic derecho → *New File*, pegas el contenido, guardas con Ctrl+S. Ves los resultados en la **consola de BigQuery**. La documentación se abre como **página web** (Web Preview).
- ⌨️ **Por CLI:** el mismo archivo creado con un comando `cat >` en la terminal, y un puñado de comandos `dbt ...` para construir/probar. Esos comandos `dbt` **sí o sí** se corren en terminal — pero son 4 o 5, muy simples, y te los explico uno por uno.

> 💡 **¿Quieres una experiencia 100% web?** Existe **dbt Cloud** (plan *Developer* **gratis** para 1 usuario) con un **IDE en el navegador**: escribes los modelos, corres `dbt build` y ves el lineage sin tocar una terminal. Todo el SQL de este manual funciona igual ahí; solo cambia *dónde* escribes los archivos y que le conectas BigQuery con una service account. Si el terminal te agobia, esa es tu ruta. En este manual usamos dbt-core (gratis, en Cloud Shell) porque no depende de otra cuenta.

👉 **Recomendación para semi-junior:** usa el **Open Editor** para todos los archivos (mucho más cómodo que pegar heredocs), y limítate a correr los comandos `dbt` de las secciones 4, 6, 7, 8, 9, 10 y 11.

---

## 📋 Tabla de contenido

1. [Conceptos previos](#1-conceptos-previos)
2. [¿Qué es dbt y por qué se usa?](#2-que-es-dbt)
3. [Instalar dbt y conectarlo a BigQuery](#3-instalar)
4. [Crear el proyecto dbt](#4-crear-proyecto)
5. [Definir las fuentes (sources)](#5-sources)
6. [Capa staging: limpiar y normalizar](#6-staging)
7. [Capa intermediate: features de fraude (window functions)](#7-intermediate)
8. [Capa marts: tabla final para ML](#8-marts)
9. [Tests de calidad de datos](#9-tests)
10. [Documentación y lineage](#10-docs)
11. [Ejecutar todo: dbt build](#11-build)
12. [Commit a GitHub](#12-commit)
13. [✅ Checklist final](#13-checklist)
14. [🛟 Solución de problemas](#14-troubleshooting)
15. [📖 Glosario](#15-glosario)

---

## 1. Conceptos previos

📖 **ETL vs ELT (clave para la entrevista):**
- **ETL** (Extract → **Transform** → Load): transformas los datos *antes* de cargarlos al destino. Modelo antiguo, cuando el almacenamiento era caro.
- **ELT** (Extract → Load → **Transform**): cargas los datos crudos primero (ya lo hiciste en el Manual 01) y transformas *dentro* del Data Warehouse usando su potencia de cómputo. **Es el estándar moderno** con DWs en la nube (BigQuery, Snowflake, Redshift).
- 💡 **dbt es la "T" del ELT:** transforma datos que **ya están** en el warehouse, usando solo SQL.

📖 **dbt (data build tool):** herramienta que te deja escribir transformaciones como **SELECTs de SQL** que dbt convierte en tablas/vistas, con **tests**, **documentación**, **versionado (Git)** y **dependencias** automáticas entre modelos. Es ingeniería de software aplicada a SQL.

📖 **Arquitectura por capas (medallion):**
- **staging** (silver): un modelo por cada tabla fuente; limpieza ligera (renombrar, tipos, sin lógica de negocio).
- **intermediate**: lógica reutilizable, joins y cálculos intermedios (aquí van nuestras **features de fraude**).
- **marts** (gold): tablas finales listas para consumo (ML, dashboards). Una por caso de uso.

📖 **Materialización:** cómo dbt construye un modelo en el warehouse:
- `view` → una vista (no ocupa espacio, se recalcula al consultarla). Ideal para staging/intermediate.
- `table` → una tabla física (ocupa espacio, rápida de leer). Ideal para marts.
- `incremental` → solo procesa filas nuevas (para gran volumen en producción).

💡 **El flujo de este manual:** `fraud_raw.*` (crudo) → **staging** (limpio) → **intermediate** (features) → **marts** (`mart_fraud_features`, listo para ML).

🔁 **En AWS:** dbt funciona igual; solo cambias el *adapter* (`dbt-redshift`, `dbt-snowflake`, `dbt-athena`) y el `profiles.yml`. Los modelos SQL son casi idénticos. Por eso dbt es una habilidad **portable entre nubes**.

---

## 2. Que es dbt

Antes de instalar, ten claro **qué resuelve** dbt (te lo van a preguntar):
- **Reproducibilidad:** tus transformaciones son código versionado en Git, no consultas sueltas.
- **Calidad:** tests declarativos (`not_null`, `unique`, etc.) que corren con un comando.
- **Dependencias automáticas:** con `ref()`, dbt sabe el orden correcto de construcción y dibuja el **lineage** (grafo de dependencias).
- **Documentación viva:** generas un sitio web navegable de tus datos.
- **Modularidad:** divides lógica compleja en piezas reutilizables.

> Usaremos **dbt-core** (gratis, open-source, corre en Cloud Shell). Alternativa 100% web: **dbt Cloud** (plan Developer gratis, IDE en el navegador) — ver la nota del inicio.

---

## 3. Instalar

> Esta sección es de terminal (instalar y autenticar). Son 3 comandos; luego casi todo lo escribes en el editor visual.

### Paso 3.1 — Abrir Cloud Shell e instalar dbt-bigquery
```bash
pip install --user dbt-bigquery
dbt --version
```
💡 `dbt-bigquery` instala dbt-core + el adaptador de BigQuery. Debe mostrar `Core: 1.x` e `installed: bigquery`. Si dice "command not found", usa `python3 -m dbt --version` o añade `export PATH=$PATH:~/.local/bin`.

### Paso 3.2 — Autenticar dbt con BigQuery
dbt necesita credenciales para conectarse. Usaremos **OAuth** vía tu sesión de gcloud (lo más simple en Cloud Shell):
```bash
gcloud auth application-default login
```
Sigue el enlace/código que aparece y autoriza. Esto crea las "Application Default Credentials" que dbt usará.

🛟 *Si en Cloud Shell ya estás autenticado*, igual ejecuta el comando para asegurar las credenciales de aplicación (ADC), que son distintas de las de la CLI.

### ✅ Checkpoint 3
`dbt --version` muestra core + bigquery. Autenticación de aplicación completada sin error.

---

## 4. Crear proyecto

Construiremos el proyecto dbt **manualmente** dentro de la carpeta `dbt_project/` que ya creaste (así entiendes cada archivo, en vez de usar plantillas automáticas). A partir de aquí, **crea cada archivo con el editor visual** (Open Editor → clic derecho → New File) y pega el contenido; el `cat >` es la alternativa por terminal.

### Paso 4.1 — Archivo de conexión: `~/.dbt/profiles.yml`
dbt busca las conexiones en `~/.dbt/profiles.yml` (una carpeta oculta en tu home).

🖱️ **Por la UI:** en Open Editor, menú **File → Open…** escribe la ruta `/home/<tu_usuario>/.dbt/` (créala si no existe), y crea `profiles.yml` con este contenido (cambia `<TU_PROJECT_ID>`):
```yaml
fraudshield:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth
      project: <TU_PROJECT_ID>
      dataset: fraud_dbt
      location: us-central1
      threads: 4
      timeout_seconds: 300
      priority: interactive
```

⌨️ **Por CLI (rellena el Project ID automáticamente):**
```bash
mkdir -p ~/.dbt
export PROJECT_ID=$(gcloud config get-value project)
cat > ~/.dbt/profiles.yml << EOF
fraudshield:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth
      project: ${PROJECT_ID}
      dataset: fraud_dbt
      location: us-central1
      threads: 4
      timeout_seconds: 300
      priority: interactive
EOF
```
💡 **Qué significa:** `fraudshield` = nombre del "profile"; `dataset: fraud_dbt` = dbt creará sus modelos en un dataset nuevo (separado del crudo `fraud_raw`); `method: oauth` = usa las credenciales del paso 3.2; `threads: 4` = construye hasta 4 modelos en paralelo.

### Paso 4.2 — Archivo del proyecto: `dbt_project/dbt_project.yml`
Crea `~/fraudshield/dbt_project/dbt_project.yml` (por editor o `cat >`):
```yaml
name: 'fraudshield'
version: '1.0.0'
config-version: 2

# Enlaza con el profile de ~/.dbt/profiles.yml
profile: 'fraudshield'

model-paths: ["models"]
test-paths: ["tests"]

# Materialización por capa
models:
  fraudshield:
    staging:
      +materialized: view
    intermediate:
      +materialized: view
    marts:
      +materialized: table
```

### Paso 4.3 — Crear las carpetas de modelos

🖱️ **Por la UI:** en Open Editor, clic derecho sobre `dbt_project` → New Folder → crea `models`, y dentro de `models` crea `staging`, `intermediate`, `marts`. Crea también `tests` al nivel de `dbt_project`.

⌨️ **Por CLI:**
```bash
cd ~/fraudshield/dbt_project
mkdir -p models/staging models/intermediate models/marts tests
```

### Paso 4.4 — Verificar la conexión (terminal)
```bash
cd ~/fraudshield/dbt_project
dbt debug
```
Busca la línea final: **`All checks passed!`** 🎉

🛟 *Si falla "profile not found":* revisa que `profile:` en `dbt_project.yml` diga `fraudshield` y que `~/.dbt/profiles.yml` exista. *Si falla auth:* repite paso 3.2.

### ✅ Checkpoint 4
`dbt debug` → "All checks passed!".

---

## 5. Sources

📖 **Sources:** le dicen a dbt cuáles son tus tablas crudas de entrada (las del Manual 01). Permiten usar `{{ source(...) }}` y testear los datos de origen.

Crea `~/fraudshield/dbt_project/models/staging/_sources.yml` (editor o `cat >`):
```yaml
version: 2

sources:
  - name: fraud_raw
    description: "Datos crudos cargados desde el Data Lake (Manual 01)."
    schema: fraud_raw
    tables:
      - name: transactions
        description: "Transacciones bancarias (PaySim). ~6.3M filas."
      - name: complaints
        description: "Quejas de clientes con narrativa (CFPB)."
```

### ✅ Checkpoint 5
El archivo `models/staging/_sources.yml` existe.

---

## 6. Staging

📖 La capa **staging** hace limpieza ligera: renombra columnas a nombres claros, asegura tipos, **sin lógica de negocio**. Un modelo por tabla fuente.

### Paso 6.1 — `models/staging/stg_transactions.sql`
```sql
-- Limpieza y normalización de las transacciones crudas.
with source as (
    select * from {{ source('fraud_raw', 'transactions') }}
),

renamed as (
    select
        step,
        hour_of_day,
        type                         as transaction_type,
        cast(amount as float64)      as amount,
        name_orig                    as account_orig,
        cast(old_balance_orig as float64)  as old_balance_orig,
        cast(new_balance_orig as float64)  as new_balance_orig,
        name_dest                    as account_dest,
        cast(old_balance_dest as float64)  as old_balance_dest,
        cast(new_balance_dest as float64)  as new_balance_dest,
        cast(is_fraud as int64)            as is_fraud,
        cast(is_flagged_fraud as int64)    as is_flagged_fraud
    from source
)

select * from renamed
```

### Paso 6.2 — `models/staging/stg_complaints.sql`
```sql
-- Limpieza de las quejas de clientes (texto no estructurado).
-- Nota: ajusta los nombres de columna si tu carga difiere (revisa en la consola de BigQuery
-- el esquema de fraud_raw.complaints).
with source as (
    select * from {{ source('fraud_raw', 'complaints') }}
)

select
    *
from source
```
💡 Dejamos `stg_complaints` simple; lo usará el RAG (Manual 05). Si quieres, más adelante seleccionas solo las columnas relevantes (fecha, producto, issue, narrativa).

### Paso 6.3 — Construir la capa staging (terminal)
```bash
cd ~/fraudshield/dbt_project
dbt run --select staging
```
Salida esperada: `Completed successfully`, con 2 modelos creados como **vistas** en el dataset `fraud_dbt`.

🖱️ **Verifica en la UI:** consola → **BigQuery** → expande `fraud_dbt` → deben aparecer las vistas `stg_transactions` y `stg_complaints`. Clic en una → pestaña **PREVIEW** para ver datos.

### ✅ Checkpoint 6
En BigQuery aparecen las vistas `stg_transactions` y `stg_complaints`.

---

## 7. Intermediate

Aquí está el **corazón del feature engineering de fraude**. Calculamos señales que distinguen transacciones fraudulentas, usando **window functions**.

### Paso 7.1 — `models/intermediate/int_account_activity.sql`
```sql
-- Features de fraude por transacción, con contexto de comportamiento de la cuenta.
with tx as (
    select * from {{ ref('stg_transactions') }}
),

features as (
    select
        *,

        -- 1) ERROR DE SALDO (señal fuerte de fraude):
        -- en un movimiento legítimo, old_balance_orig - amount ≈ new_balance_orig
        round(old_balance_orig - amount - new_balance_orig, 2) as balance_error_orig,
        round(new_balance_dest - old_balance_dest - amount, 2) as balance_error_dest,

        -- 2) VELOCIDAD: nº de transacciones previas de la misma cuenta de origen
        count(*) over (
            partition by account_orig
            order by step
            rows between unbounded preceding and current row
        ) as tx_count_orig,

        -- 3) MONTO ACUMULADO por la cuenta de origen
        sum(amount) over (
            partition by account_orig
            order by step
            rows between unbounded preceding and current row
        ) as cum_amount_orig,

        -- 4) TIEMPO desde la transacción anterior de la misma cuenta (en steps/horas)
        step - lag(step) over (
            partition by account_orig order by step
        ) as steps_since_prev_orig,

        -- 5) ¿La cuenta de origen vacía su saldo? (patrón típico de fraude)
        case when new_balance_orig = 0 and old_balance_orig > 0 then 1 else 0 end as drained_account_flag

    from tx
)

select * from features
```
💡 **Por qué estas features:** en PaySim el fraude casi siempre **vacía la cuenta** (`drained_account_flag`) y produce **errores de saldo**. La **velocidad** y el **tiempo entre transacciones** capturan comportamiento anómalo. Esto es exactamente lo que explicarías en entrevista sobre feature engineering de fraude.

### Paso 7.2 — Construir (terminal)
```bash
dbt run --select intermediate
```

### ✅ Checkpoint 7
La vista `int_account_activity` existe en `fraud_dbt`. Pruébala en el **editor de BigQuery** (Compose new query → RUN):
```sql
SELECT account_orig, step, amount, balance_error_orig, tx_count_orig, drained_account_flag, is_fraud
FROM `fraud_dbt.int_account_activity`
WHERE is_fraud = 1 LIMIT 10;
```

---

## 8. Marts

La capa **marts** produce la tabla final, materializada como **tabla física** (rápida para que el modelo de ML la lea muchas veces).

### Paso 8.1 — `models/marts/mart_fraud_features.sql`
```sql
-- Tabla final de features lista para entrenar el modelo de fraude (Manual 04).
with f as (
    select * from {{ ref('int_account_activity') }}
)

select
    -- identificadores / contexto
    step,
    hour_of_day,
    transaction_type,
    is_high_risk_type,

    -- montos y saldos
    amount,
    old_balance_orig,
    new_balance_orig,
    old_balance_dest,
    new_balance_dest,

    -- features derivadas
    balance_error_orig,
    balance_error_dest,
    tx_count_orig,
    cum_amount_orig,
    coalesce(steps_since_prev_orig, -1) as steps_since_prev_orig,
    drained_account_flag,

    -- etiqueta objetivo
    is_fraud

from (
    select
        *,
        case when transaction_type in ('TRANSFER', 'CASH_OUT') then 1 else 0 end as is_high_risk_type
    from f
)
```
💡 `is_high_risk_type` codifica que el fraude en PaySim **solo** ocurre en `TRANSFER` y `CASH_OUT` — una feature potentísima.

### Paso 8.2 — Construir el mart (terminal)
```bash
dbt run --select marts
```
Esto crea la **tabla** `fraud_dbt.mart_fraud_features`. 🖱️ Verifícalo en la consola de BigQuery, o por CLI:
```bash
bq query --use_legacy_sql=false \
'SELECT COUNT(*) AS filas, SUM(is_fraud) AS fraudes FROM `fraud_dbt.mart_fraud_features`'
```

### ✅ Checkpoint 8
`fraud_dbt.mart_fraud_features` es una **tabla** con ~6.3M filas y la columna `is_fraud`. Esta es la entrada del Manual 04.

---

## 9. Tests

📖 Los **tests de dbt** validan la calidad **automáticamente**. Hay dos tipos:
- **Genéricos:** se declaran en YAML (`not_null`, `unique`, `accepted_values`, `relationships`).
- **Singulares:** una consulta SQL en `tests/` que **falla si devuelve filas**.

### Paso 9.1 — Tests genéricos: `models/marts/_models.yml`
```yaml
version: 2

models:
  - name: stg_transactions
    description: "Transacciones limpias y tipadas."
    columns:
      - name: amount
        description: "Monto de la transacción."
        tests:
          - not_null
      - name: is_fraud
        description: "1 = fraude, 0 = legítima."
        tests:
          - not_null
          - accepted_values:
              values: [0, 1]

  - name: mart_fraud_features
    description: "Tabla de features lista para el modelo de detección de fraude."
    columns:
      - name: is_fraud
        description: "Etiqueta objetivo."
        tests:
          - not_null
          - accepted_values:
              values: [0, 1]
      - name: amount
        tests:
          - not_null
      - name: transaction_type
        tests:
          - not_null
          - accepted_values:
              values: ['CASH_IN', 'CASH_OUT', 'DEBIT', 'PAYMENT', 'TRANSFER']
```

### Paso 9.2 — Test singular: `tests/assert_no_negative_amounts.sql`
Un test que verifica que **no existan montos negativos** (no deberían):
```sql
-- Falla si hay montos negativos (calidad de datos).
select *
from {{ ref('stg_transactions') }}
where amount < 0
```

### Paso 9.3 — Correr los tests (terminal)
```bash
cd ~/fraudshield/dbt_project
dbt test
```
Salida esperada: todos `PASS`. 🎉

💡 **Para la entrevista:** "uso `dbt test` para validar nulos, valores aceptados y reglas de negocio en cada corrida; si un test falla, el pipeline se detiene". Esto es **calidad de datos declarativa** (requisito explícito de Ceiba).

🛟 *Si `accepted_values` de `transaction_type` falla:* revisa los valores reales con `SELECT DISTINCT transaction_type FROM fraud_dbt.stg_transactions` y ajusta la lista.

### ✅ Checkpoint 9
`dbt test` → todos los tests en `PASS`.

---

## 10. Docs

📖 dbt genera un **sitio web navegable** con la documentación y el **lineage** (grafo de dependencias entre modelos). Es oro para mostrar en entrevista, y es **100% visual**.

### Paso 10.1 — Generar y servir la documentación (terminal → web)
```bash
cd ~/fraudshield/dbt_project
dbt docs generate
dbt docs serve --port 8080
```

🖱️ **Ábrelo en el navegador:** en la barra de Cloud Shell, clic en **"Web Preview"** (ícono de pantalla, arriba a la derecha del panel) → **"Preview on port 8080"**. Se abre el sitio de dbt.
- Explora los modelos, sus descripciones y columnas.
- Clic en el botón inferior derecho del **lineage graph** → verás la cadena:
  `source.transactions → stg_transactions → int_account_activity → mart_fraud_features`

Para detener el servidor: `Ctrl + C` en la terminal.

### ✅ Checkpoint 10
Ves el sitio de dbt docs y el **grafo de lineage** con la cadena completa de modelos.

---

## 11. Build

📖 `dbt build` = `dbt run` + `dbt test` en el **orden correcto de dependencias** (construye un modelo y lo testea antes de seguir). Es el comando que usarás en producción (y que Airflow ejecutará en el Manual 03).

```bash
cd ~/fraudshield/dbt_project
dbt build
```
Verás cada modelo construirse y testearse en orden. Al final: resumen con todo en `PASS`/`success`.

💡 **Costo:** construir `mart_fraud_features` escanea ~6.3M filas una vez (pocos cientos de MB) → muy por debajo del 1 TB gratis mensual de BigQuery.

### ✅ Checkpoint 11
`dbt build` termina sin errores. En `fraud_dbt` tienes: vistas `stg_*`, `int_account_activity` y la tabla `mart_fraud_features`.

---

## 12. Commit

🖱️ **Por la UI (VS Code / Cloud Shell Editor):** panel Source Control → mensaje → ✓ Commit → Push. Antes, asegúrate de ignorar los artefactos de dbt (abajo).

⌨️ **Por CLI:**
```bash
cd ~/fraudshield
printf '\n# dbt\ndbt_project/target/\ndbt_project/dbt_packages/\ndbt_project/logs/\n' >> .gitignore
git add dbt_project/ .gitignore
git commit -m "Manual 02: proyecto dbt (ELT) con staging/intermediate/marts, features de fraude y tests de calidad"
git push origin main
```
💡 **No se sube** `~/.dbt/profiles.yml` (está fuera del repo) ni el directorio `target/` de dbt.

### ✅ Checkpoint 12
En GitHub aparece la carpeta `dbt_project/` con tus modelos y tests.

---

## 13. Checklist

- [ ] `dbt-bigquery` instalado; `dbt debug` → "All checks passed!".
- [ ] `profiles.yml` y `dbt_project.yml` configurados.
- [ ] Sources declaradas (`_sources.yml`).
- [ ] Capa staging (`stg_transactions`, `stg_complaints`) construida.
- [ ] Capa intermediate (`int_account_activity`) con features de fraude (error de saldo, velocidad, drenaje de cuenta).
- [ ] Mart `mart_fraud_features` materializado como tabla (~6.3M filas).
- [ ] `dbt test` → todos PASS (genéricos + singular).
- [ ] `dbt docs` y lineage visualizados.
- [ ] `dbt build` corre completo.
- [ ] Commit en GitHub.

Si todo está ✅ → **listo para el Manual 03: Orquestación con Airflow (Cloud Composer).**

---

## 14. Troubleshooting

| Problema | Causa | Solución |
|---|---|---|
| `dbt: command not found` | No está en PATH | `python3 -m dbt ...` o `export PATH=$PATH:~/.local/bin`. |
| `dbt debug` falla en auth | Faltan ADC | Repite `gcloud auth application-default login`. |
| "Profile fraudshield not found" | Nombre no coincide | `profile:` en `dbt_project.yml` debe ser `fraudshield` y existir en `~/.dbt/profiles.yml`. |
| "Dataset not found: fraud_raw" | Región o nombre | Confirma que el Manual 01 creó `fraud_raw` en `us-central1`; `location` del profile debe ser `us-central1`. |
| `accepted_values` falla en `transaction_type` | Valores distintos | `SELECT DISTINCT transaction_type ...` y ajusta la lista. |
| Columnas no existen en `stg_complaints` | El CSV de CFPB tenía otros nombres | Revisa el esquema en la consola de BigQuery y ajusta el SELECT. |
| `dbt docs serve` no abre | Puerto/Preview | Usa "Web Preview → port 8080"; o cambia `--port 8081`. |
| Build lento | Window functions sobre 6.3M | Normal la primera vez; el mart queda como tabla y luego es rápido. |

---

## 15. Glosario

- **ELT:** Extract-Load-Transform; transformar dentro del warehouse (estándar moderno).
- **dbt:** herramienta para transformar datos en el DW con SQL + tests + docs + Git.
- **dbt-core vs dbt Cloud:** core es gratis y corre en tu terminal; Cloud es un IDE web (plan Developer gratis) que hace lo mismo sin terminal.
- **Modelo (dbt):** un archivo `.sql` con un `SELECT` que dbt materializa.
- **`ref()`:** referencia a otro modelo; crea dependencias y lineage.
- **`source()`:** referencia a una tabla cruda de entrada.
- **Materialización:** `view` / `table` / `incremental`.
- **Staging / intermediate / marts:** capas silver / lógica / gold.
- **Feature engineering:** crear variables predictivas (error de saldo, velocidad, drenaje).
- **Test genérico vs singular:** YAML (`not_null`...) vs consulta SQL que falla si devuelve filas.
- **Lineage:** grafo de dependencias entre modelos.
- **`dbt build`:** run + test en orden de dependencias.

---

> **⬅️ Anterior:** [Manual 01 — Ingesta y Data Lake](./01_ingesta_datos_y_data_lake.md)
> **➡️ Siguiente:** Manual 03 — Orquestación con Airflow (Cloud Composer) _(en construcción)_
