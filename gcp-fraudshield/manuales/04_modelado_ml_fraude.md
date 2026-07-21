# Manual 04 — Modelado de ML (detección de fraude)

> **Objetivo:** Entrenar modelos de detección de fraude sobre la tabla `mart_fraud_features` (del Manual 02), siguiendo **CRISP-DM**. Aprenderás a manejar el reto central del fraude —**clases desbalanceadas**—, a elegir las **métricas correctas** (¡la accuracy engaña!), a entrenar un baseline en **BigQuery ML** (SQL, cloud) y un modelo avanzado **XGBoost** en Python con **explicabilidad SHAP**, y a guardar el modelo para producción (Manual 06).
>
> **Tiempo estimado:** 6–8 horas.
> **Prerrequisito:** Manual 02 completo (`fraud_dbt.mart_fraud_features` existe).
> **Cubre del cargo:** modelamiento estadístico y ML **tradicional y avanzado**, EDA, CRISP-DM (Ceiba) · ML sólido y explicable (Proxify).
> **Nube:** GCP (BigQuery ML) + Python (Vertex AI Workbench, Cloud Shell o tu PC local). 🔁 callout AWS (SageMaker).

---

## 🖱️ / ⌨️ Cómo leer este manual (mitad SQL visual, mitad Python)

Este manual tiene dos mundos, y ambos pueden ser muy visuales:

- **EDA + baseline (BigQuery ML) = 100% UI.** Todo es **SQL que corres en la consola de BigQuery** (Compose new query → RUN). Y lo mejor: cuando entrenas un modelo con BQML, BigQuery te muestra sus métricas en **pestañas visuales con gráficos** (curva ROC, precision-recall, matriz de confusión) — sin escribir código de gráficas.
- **XGBoost + SHAP = Python.** Aquí sí hay código. La forma **más visual** de correrlo en GCP es un **notebook de Vertex AI Workbench** (celdas que ejecutas con un botón ▶, ves tablas y gráficas al instante — como Jupyter). También sirve el editor de Cloud Shell o tu PC local.

👉 **Para semi-junior:** haz el EDA y el baseline enteros en la **consola de BigQuery** (súper cómodo). Para el XGBoost, usa un **notebook de Vertex AI** (te guío para crearlo) en vez de la terminal — verás cada resultado paso a paso.

---

## 📋 Tabla de contenido

1. [Conceptos previos](#1-conceptos-previos)
2. [CRISP-DM aplicado a este proyecto](#2-crisp-dm)
3. [El reto del fraude: clases desbalanceadas y métricas](#3-desbalanceo)
4. [Fase 2 (CRISP-DM): Entendimiento de los datos (EDA)](#4-eda)
5. [Fase 3: Preparación de los datos (y fuga de datos)](#5-preparacion)
6. [Fase 4a: Baseline en BigQuery ML (SQL, cloud)](#6-bqml)
7. [Fase 4b: Modelo avanzado XGBoost en Python](#7-xgboost)
8. [Fase 5: Evaluación y explicabilidad (SHAP)](#8-evaluacion)
9. [Guardar el modelo para producción](#9-guardar)
10. [Commit a GitHub](#10-commit)
11. [✅ Checklist final](#11-checklist)
12. [🛟 Solución de problemas](#12-troubleshooting)
13. [📖 Glosario](#13-glosario)

---

## 1. Conceptos previos

📖 **Aprendizaje supervisado / clasificación:** entrenamos un modelo con ejemplos etiquetados (`is_fraud` = 0 o 1) para que aprenda a predecir la etiqueta de transacciones nuevas. Es un problema de **clasificación binaria**.

📖 **Baseline vs modelo avanzado:** siempre empiezas con un modelo simple (regresión logística) como **punto de referencia**, y luego pruebas uno avanzado (XGBoost). Si el avanzado no supera al baseline, algo va mal. 💡 En entrevista: "siempre comparo contra un baseline".

📖 **Features (X) y etiqueta (y):** las columnas predictoras (monto, error de saldo, velocidad...) son `X`; la columna a predecir (`is_fraud`) es `y`.

📖 **Train / Validation / Test:** dividimos los datos: **train** para aprender, **validation** para ajustar, **test** para medir el desempeño real en datos no vistos. Nunca mires el test hasta el final.

💡 **El plan de este manual:** entender datos → preparar → baseline (BQML) → XGBoost → evaluar y explicar → guardar modelo.

---

## 2. CRISP-DM

📖 **CRISP-DM** (Cross-Industry Standard Process for Data Mining) es la metodología que pide Ceiba. Son **6 fases** (iterativas):

| Fase | Qué es | Dónde la haces aquí |
|---|---|---|
| 1. **Entendimiento del negocio** | Definir el objetivo de negocio | El banco quiere **detectar fraude** minimizando pérdidas (ver §3) |
| 2. **Entendimiento de los datos** | Explorar, EDA, calidad | §4 |
| 3. **Preparación de los datos** | Limpiar, features, split | §5 (y ya hiciste mucho en dbt, Manual 02) |
| 4. **Modelado** | Entrenar modelos | §6 (BQML) y §7 (XGBoost) |
| 5. **Evaluación** | Medir contra el objetivo de negocio | §8 |
| 6. **Despliegue** | Poner en producción | Manuales 06–07 |

> 💡 **Para la entrevista:** memoriza las 6 fases y di "apliqué CRISP-DM: empecé por el objetivo de negocio (reducir pérdidas por fraude), exploré los datos, los preparé con dbt, modelé un baseline y un XGBoost, evalué con métricas de negocio y lo desplegué".

### Fase 1 — Entendimiento del negocio (defínelo ya)
- **Objetivo de negocio:** detectar transacciones fraudulentas para bloquearlas/revisarlas, **minimizando pérdidas** sin molestar demasiado a clientes legítimos.
- **Traducción a ML:** clasificar cada transacción como fraude (1) o no (0), priorizando **atrapar el máximo de fraude (recall)** con una **precisión razonable**.
- **Costo de errores:** un **falso negativo** (fraude no detectado) = dinero perdido; un **falso positivo** (legítima marcada) = molestia al cliente y costo operativo de revisión. El balance depende del negocio.

---

## 3. Desbalanceo

Este es **el** tema que distingue a quien sabe de fraude. Domínalo.

### 3.1 — El problema
En `mart_fraud_features`, solo **~0.13%** de las transacciones son fraude. Si un modelo dijera "todo es legítimo", acertaría el **99.87%**... y sería **inútil** (no atrapa ni un fraude).

> 🔴 **Por eso la `accuracy` (exactitud) NO sirve en fraude.** Es la trampa clásica.

### 3.2 — Las métricas correctas
| Métrica | Qué mide | Por qué importa en fraude |
|---|---|---|
| **Precision** | De lo que marqué como fraude, ¿cuánto era fraude real? | Evita molestar clientes legítimos (falsos positivos) |
| **Recall (sensibilidad)** | Del fraude real, ¿cuánto atrapé? | Evita dejar pasar fraude (falsos negativos) |
| **F1** | Balance entre precision y recall | Resumen cuando ambos importan |
| **AUC-PR** (área bajo la curva Precision-Recall) | Desempeño global con desbalanceo | **La métrica reina en fraude** (mejor que ROC-AUC cuando hay desbalanceo extremo) |
| **Matriz de confusión** | TP, FP, FN, TN | Ver el costo real de cada tipo de error |

💡 **Frase para entrevista:** "En fraude optimizo **AUC-PR y recall**, no accuracy, porque las clases están muy desbalanceadas; y razono el **costo de falsos negativos vs falsos positivos**."

### 3.3 — Cómo manejar el desbalanceo (técnicas)
1. **Pesos de clase** (`class_weight` / `scale_pos_weight`): le dices al modelo que un fraude "vale" más. (Lo usaremos.)
2. **Resampling:** **oversampling** de la clase minoritaria (ej. **SMOTE**) o **undersampling** de la mayoritaria. (Librería `imbalanced-learn`.)
3. **Ajuste de umbral (threshold):** en vez del 0.5 por defecto, elegir el umbral que mejor equilibra precision/recall para el negocio. (Lo haremos.)

### ✅ Checkpoint 3
Puedes explicar por qué la accuracy engaña y qué es AUC-PR.

---

## 4. EDA

📖 **EDA (Análisis Exploratorio de Datos):** entender los datos antes de modelar. Lo haremos con SQL sobre el mart (rápido, sin descargar nada).

🖱️ **Por la UI:** consola → **BigQuery** → **Compose new query** → pega cada consulta → **RUN**. Los resultados salen en una tabla abajo; puedes cambiar a la pestaña **CHART** para graficarlos con clics.

### 4.1 — Distribución de la etiqueta
```sql
SELECT is_fraud, COUNT(*) AS n,
       ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 4) AS pct
FROM `fraud_dbt.mart_fraud_features`
GROUP BY is_fraud;
```
Confirma el desbalanceo (~0.13% fraude).

### 4.2 — Fraude por tipo de transacción
```sql
SELECT transaction_type,
       COUNT(*) AS n, SUM(is_fraud) AS fraudes,
       ROUND(SUM(is_fraud)/COUNT(*)*100, 4) AS pct_fraude
FROM `fraud_dbt.mart_fraud_features`
GROUP BY transaction_type
ORDER BY fraudes DESC;
```
💡 Verás que el fraude **solo** aparece en `TRANSFER` y `CASH_OUT` → tu feature `is_high_risk_type` es muy informativa.

### 4.3 — ¿Las features separan las clases? (señal predictiva)
```sql
SELECT is_fraud,
       ROUND(AVG(amount), 2)              AS monto_prom,
       ROUND(AVG(balance_error_orig), 2)  AS error_saldo_prom,
       ROUND(AVG(drained_account_flag), 4) AS pct_cuenta_drenada,
       ROUND(AVG(tx_count_orig), 1)       AS tx_promedio
FROM `fraud_dbt.mart_fraud_features`
GROUP BY is_fraud;
```
💡 Si los promedios difieren mucho entre fraude y no-fraude, esas features **sirven**. Verás que las cuentas fraudulentas se drenan casi siempre y tienen montos/errores de saldo distintos.

### 4.4 — (Opcional) Perfilado automático
Si quieres un reporte visual, descarga una muestra y usa `ydata-profiling` en un notebook. No es obligatorio; el EDA por SQL ya te da lo esencial.

### ✅ Checkpoint 4
Entiendes: el desbalanceo, que el fraude se concentra en 2 tipos, y que tus features separan las clases.

---

## 5. Preparacion

📖 Gran parte de la preparación **ya la hiciste con dbt** (limpieza, features, tipos). Aquí faltan 2 cosas críticas: **evitar fuga de datos** y **crear la muestra de entrenamiento**.

### 5.1 — ⚠️ Fuga de datos (data leakage) — concepto senior
📖 **Fuga de datos:** usar como feature algo que el modelo **no tendría disponible al momento de predecir**, o que es prácticamente la respuesta. Infla las métricas y arruina el modelo en producción.

En nuestro caso:
- ❌ **Excluimos `step`** (índice de tiempo crudo 1–744): no generaliza a fechas nuevas y puede memorizar el periodo. (En dbt ya derivamos `hour_of_day`, que sí sirve.)
- ❌ Si existiera `is_flagged_fraud` (la marca del sistema antiguo), **no se usa como feature** (sería casi la respuesta). Ya lo dejamos fuera del mart en el Manual 02. ✅
- ✅ Las demás features (montos, saldos, errores, velocidad, drenaje) **sí** están disponibles al momento de la transacción.

💡 **Frase para entrevista:** "Reviso explícitamente la fuga de datos: excluyo índices de tiempo y cualquier señal que sea proxy de la etiqueta o que no exista en tiempo de inferencia."

### 5.2 — Crear una muestra de entrenamiento manejable
Entrenar XGBoost sobre 6.3M filas es pesado. Creamos una **muestra**: **todo el fraude** + una fracción del no-fraude. Reduce tamaño y atenúa el desbalanceo (luego el modelo y el umbral lo terminan de manejar).

🖱️ **Por la UI (consola de BigQuery):** pega esta consulta en el editor y **RUN**. Luego, en los resultados, clic en **SAVE RESULTS → BigQuery table** → dataset `fraud_dbt`, tabla `train_sample`. (O usa el `CREATE TABLE AS` de abajo directamente.)
```sql
CREATE OR REPLACE TABLE `fraud_dbt.train_sample` AS
SELECT * EXCEPT(step) FROM `fraud_dbt.mart_fraud_features` WHERE is_fraud = 1
UNION ALL
SELECT * EXCEPT(step) FROM `fraud_dbt.mart_fraud_features` WHERE is_fraud = 0 AND RAND() < 0.04;
```

⌨️ **Equivalente en CLI:**
```bash
bq query --use_legacy_sql=false --replace \
  --destination_table=fraud_dbt.train_sample \
'SELECT * EXCEPT(step) FROM `fraud_dbt.mart_fraud_features` WHERE is_fraud = 1
 UNION ALL
 SELECT * EXCEPT(step) FROM `fraud_dbt.mart_fraud_features` WHERE is_fraud = 0 AND RAND() < 0.04'
```
💡 `RAND() < 0.04` toma ~4% del no-fraude (~250k filas) + los ~8k fraudes → ~260k filas, manejable.

### 5.3 — Exportar la muestra para Python

🖱️ **Por la UI:** BigQuery → Explorer → tabla `train_sample` → menú **⋮** → **Export → Export to GCS** → destino `.../curated/train_sample.csv`, formato CSV.

⌨️ **Equivalente en CLI:**
```bash
export PROJECT_ID=$(gcloud config get-value project)
export BUCKET="gs://${PROJECT_ID}-datalake"
bq extract --destination_format=CSV \
  fraud_dbt.train_sample \
  "$BUCKET/curated/train_sample.csv"
gcloud storage cp "$BUCKET/curated/train_sample.csv" ~/fraudshield/ml/
ls -lh ~/fraudshield/ml/train_sample.csv
```
💡 Si trabajarás en un **notebook de Vertex AI** (§7), puedes saltarte la descarga local y leer el CSV directo desde GCS con `pd.read_csv("gs://.../train_sample.csv")`.

### ✅ Checkpoint 5
Existe la tabla `fraud_dbt.train_sample` (~260k filas) y su CSV en GCS. Entiendes qué es la fuga de datos.

---

## 6. Bqml

📖 **BigQuery ML** te deja **entrenar modelos con SQL**, sin mover datos ni montar infraestructura. Perfecto como baseline cloud-native (muy bien visto en Ceiba/GCP). Todo esto es **por UI** en el editor de BigQuery.

### 6.1 — Entrenar una regresión logística (baseline)
Pega en el editor de BigQuery y **RUN**:
```sql
CREATE OR REPLACE MODEL `fraud_dbt.fraud_logreg`
OPTIONS(
  model_type = 'LOGISTIC_REG',
  input_label_cols = ['is_fraud'],
  auto_class_weights = TRUE,          -- maneja el desbalanceo
  data_split_method = 'RANDOM',
  data_split_eval_fraction = 0.2      -- 20% para evaluación
) AS
SELECT
  hour_of_day, transaction_type, is_high_risk_type, amount,
  old_balance_orig, new_balance_orig, old_balance_dest, new_balance_dest,
  balance_error_orig, balance_error_dest, tx_count_orig, cum_amount_orig,
  steps_since_prev_orig, drained_account_flag,
  is_fraud
FROM `fraud_dbt.mart_fraud_features`;
```
💡 `auto_class_weights = TRUE` es la forma de BQML de manejar el desbalanceo. Entrena en 1–3 min.

### 6.2 — Evaluar el baseline (¡con gráficos automáticos!)

🖱️ **Por la UI (lo más visual):** en el Explorer de BigQuery, expande `fraud_dbt` → **Models** → clic en `fraud_logreg`. Verás pestañas:
- **EVALUATION:** precision, recall, F1, ROC-AUC, y **gráficas de curva ROC y precision-recall** ya dibujadas.
- **Confusion matrix:** matriz TP/FP/FN/TN interactiva (puedes mover el umbral con un slider).

⌨️ **Equivalente por SQL:**
```sql
SELECT * FROM ML.EVALUATE(MODEL `fraud_dbt.fraud_logreg`);
SELECT * FROM ML.CONFUSION_MATRIX(MODEL `fraud_dbt.fraud_logreg`);
```
Anota el **recall** (cuánto fraude atrapa el baseline) — es el número a superar.

🔁 **En AWS:** el equivalente sería entrenar en **SageMaker** (o SageMaker Autopilot). BQML es la vía rápida en GCP; SageMaker es la de AWS.

### ✅ Checkpoint 6
Tienes el modelo `fraud_logreg` evaluado (viste su pestaña EVALUATION), con su recall/precision anotados como **baseline a superar**.

---

## 7. Xgboost

Ahora el modelo avanzado en Python: **XGBoost** con manejo explícito de desbalanceo, ajuste de umbral y explicabilidad.

> 💻 **Dónde correrlo (elige el más cómodo):**
> - 🖱️ **Vertex AI Workbench (notebook, lo más visual)** — recomendado. Ves cada resultado (tablas, la gráfica SHAP) al instante, como Jupyter. Ver 7.1.
> - **Cloud Shell** — funciona (la muestra es pequeña); corres el script con `python3`.
> - **Tu PC local (RTX 4070 Super, 64 GB)** — para más velocidad/datos; mismo código.

### 7.1 — (Opción visual) Crear un notebook en Vertex AI Workbench 🖱️
1. Consola → menú **☰** → **Vertex AI** → **Workbench**.
2. Botón **CREATE** (instancia). Deja los valores por defecto (una máquina pequeña basta), región `us-central1` → **CREATE**. Tarda ~3 min.
3. Cuando esté lista, clic en **OPEN JUPYTERLAB**.
4. Dentro de JupyterLab: **File → New → Notebook** (kernel Python 3). Pega el código de 7.2 en celdas y ejecútalas con **Shift+Enter**. Verás las métricas y la gráfica SHAP en pantalla.
5. ⚠️ **Al terminar, apaga la instancia** (Workbench → selecciona la instancia → **STOP**) para no gastar. Solo cobra mientras está encendida.

### 7.2 — El código de entrenamiento
Si usas notebook, pega esto por celdas. Si prefieres terminal, guárdalo como `~/fraudshield/ml/train.py` (por Open Editor o `cat >`) y córrelo con `python3 train.py`.

Primero, instala dependencias (en una celda con `!` delante, o en la terminal):
```bash
pip install --user xgboost scikit-learn imbalanced-learn shap matplotlib pandas pyarrow joblib
```

```python
"""
Entrena un XGBoost de detección de fraude:
 - maneja desbalanceo con scale_pos_weight
 - evalúa con AUC-PR (métrica reina en fraude)
 - ajusta el umbral de decisión
 - explica con SHAP
 - guarda el modelo para producción (Manual 06)
"""
import os
import joblib
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    classification_report, confusion_matrix,
    average_precision_score, roc_auc_score, precision_recall_curve,
)
from xgboost import XGBClassifier
import shap
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ML_DIR = os.path.expanduser("~/fraudshield/ml")
DATA = os.path.join(ML_DIR, "train_sample.csv")
# En un notebook de Vertex AI puedes leer directo de GCS:
# DATA = "gs://<TU_PROJECT_ID>-datalake/curated/train_sample.csv"

# 1) Cargar datos
df = pd.read_csv(DATA)
print(f"Datos: {df.shape[0]:,} filas, fraude = {df['is_fraud'].mean()*100:.2f}%")

# 2) One-hot encoding de la variable categórica
df = pd.get_dummies(df, columns=["transaction_type"], drop_first=True)

y = df["is_fraud"]
X = df.drop(columns=["is_fraud"])

# 3) Split estratificado (mantiene la proporción de fraude)
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, stratify=y, random_state=42
)

# 4) Manejo del desbalanceo: peso de la clase positiva
neg, pos = (y_train == 0).sum(), (y_train == 1).sum()
scale_pos_weight = neg / pos
print(f"scale_pos_weight = {scale_pos_weight:.1f}")

# 5) Entrenar XGBoost
model = XGBClassifier(
    n_estimators=300,
    max_depth=6,
    learning_rate=0.1,
    subsample=0.8,
    colsample_bytree=0.8,
    scale_pos_weight=scale_pos_weight,
    eval_metric="aucpr",
    n_jobs=-1,
    random_state=42,
)
model.fit(X_train, y_train)

# 6) Evaluación con probabilidades
proba = model.predict_proba(X_test)[:, 1]
auc_pr = average_precision_score(y_test, proba)
roc_auc = roc_auc_score(y_test, proba)
print(f"\n== Métricas globales ==\nAUC-PR : {auc_pr:.4f}\nROC-AUC: {roc_auc:.4f}")

# 7) Ajuste de umbral: el que maximiza F1
prec, rec, thr = precision_recall_curve(y_test, proba)
f1 = 2 * prec * rec / (prec + rec + 1e-9)
best = np.nanargmax(f1)
threshold = float(thr[best]) if best < len(thr) else 0.5
print(f"Umbral óptimo (F1): {threshold:.3f}")

pred = (proba >= threshold).astype(int)
print("\n== Reporte de clasificación ==")
print(classification_report(y_test, pred, digits=4))
print("Matriz de confusión [ [TN, FP], [FN, TP] ]:")
print(confusion_matrix(y_test, pred))

# 8) Explicabilidad con SHAP
print("\nCalculando SHAP (puede tardar)...")
Xs = X_test.sample(min(2000, len(X_test)), random_state=1)
explainer = shap.TreeExplainer(model)
shap_values = explainer.shap_values(Xs)
shap.summary_plot(shap_values, Xs, show=False)
plt.tight_layout()
plt.savefig(os.path.join(ML_DIR, "shap_summary.png"), dpi=120)
print("Guardado shap_summary.png")

# 9) Guardar el modelo (para el Manual 06)
joblib.dump(
    {"model": model, "threshold": threshold, "features": list(X.columns)},
    os.path.join(ML_DIR, "fraud_model.joblib"),
)
print("Modelo guardado en fraud_model.joblib")
```

### 7.3 — Ejecutar
- **Notebook:** ejecuta las celdas en orden (Shift+Enter). En un notebook, la gráfica SHAP se muestra en pantalla (puedes quitar el `matplotlib.use("Agg")` y usar `shap.summary_plot(..., show=True)`).
- **Terminal:** `cd ~/fraudshield/ml && python3 train.py`.

Se generan `shap_summary.png` y `fraud_model.joblib`.

### ✅ Checkpoint 7
El código corre completo. Tienes **AUC-PR** del XGBoost (debería ser alto, >0.9 en este dataset) y archivos `fraud_model.joblib` + `shap_summary.png`.

---

## 8. Evaluacion

### 8.1 — Comparar baseline vs avanzado
Llena esta tabla con tus resultados:

| Modelo | Recall (fraude) | Precision | AUC-PR |
|---|---|---|---|
| Logística (BQML) | ___ | ___ | (roc_auc) ___ |
| XGBoost (Python) | ___ | ___ | ___ |

💡 El XGBoost debería **superar** al baseline. Si no, revisa features/umbral.

### 8.2 — Interpretar SHAP (explicabilidad para stakeholders)
Abre `shap_summary.png` (en el notebook se muestra sola; en Cloud Shell, doble clic en el editor; o descárgalo). Muestra **qué features impulsan las predicciones de fraude**.
- Cada punto = una transacción; color = valor de la feature; posición = impacto en la predicción.
- Esperas ver `drained_account_flag`, `balance_error_orig`, `is_high_risk_type`, `amount` entre las más influyentes.

💡 **Frase para entrevista:** "Uso **SHAP** para explicar al área de riesgo *por qué* el modelo marca una transacción — por ejemplo, porque la cuenta se vació y hay un error de saldo. La explicabilidad es clave en banca (regulación y confianza)."

### 8.3 — Conectar con el negocio (Fase 5 CRISP-DM)
- "El modelo atrapa el **X% del fraude (recall)** con una precisión del **Y%**."
- "A un umbral más bajo, atrapo más fraude pero genero más revisiones; el umbral se calibra con el equipo de riesgo según el **costo de FN vs FP**."

### ✅ Checkpoint 8
Comparaste ambos modelos, interpretaste el SHAP y puedes contar el resultado en términos de negocio.

---

## 9. Guardar

Ya guardaste `fraud_model.joblib` (modelo + umbral + lista de features). Este artefacto es el que **servirá la API** en el Manual 06/07.

💡 En el Manual 06 lo registrarás formalmente con **MLflow** (versionado, métricas, model registry). Por ahora basta el `.joblib`.

🖱️ **Guardar copia en Cloud Storage (versionado de artefactos):** UI → Cloud Storage → bucket → carpeta `curated/models/` → **UPLOAD** el `.joblib`. O por CLI:
```bash
gcloud storage cp ~/fraudshield/ml/fraud_model.joblib "$BUCKET/curated/models/fraud_model.joblib"
```

🔁 **En AWS:** el artefacto se registraría en **SageMaker Model Registry**; el concepto (versionar el modelo + sus métricas) es idéntico.

### ✅ Checkpoint 9
Tienes `fraud_model.joblib` listo para producción.

---

## 10. Commit

⚠️ El modelo (`.joblib`) y el CSV son binarios/datos: **no** los subimos a Git. Subimos el **código**.

🖱️ **Por la UI (VS Code):** Source Control → commit → push (asegúrate de que `.gitignore` excluye `ml/*.joblib`, `ml/*.png`, `ml/*.csv`).

⌨️ **Por CLI:**
```bash
cd ~/fraudshield
printf '\n# Modelos y artefactos\nml/*.joblib\nml/*.png\nml/*.csv\n' >> .gitignore
git add ml/train.py .gitignore
git commit -m "Manual 04: modelado de fraude (BigQuery ML baseline + XGBoost con desbalanceo, umbral y SHAP)"
git push origin main
```

### ✅ Checkpoint 10
En GitHub aparece `ml/train.py` (sin datos ni binarios).

---

## 11. Checklist

- [ ] Entiendo y puedo explicar CRISP-DM (6 fases).
- [ ] Sé por qué la accuracy engaña y qué es AUC-PR.
- [ ] EDA hecho (en la consola de BigQuery): desbalanceo, fraude por tipo, separación de clases.
- [ ] Reviso fuga de datos (excluí `step` y la marca del sistema antiguo).
- [ ] Muestra de entrenamiento creada y exportada.
- [ ] Baseline en **BigQuery ML** entrenado y evaluado (viste la pestaña EVALUATION).
- [ ] **XGBoost** entrenado con `scale_pos_weight`, AUC-PR y umbral ajustado.
- [ ] **SHAP** generado e interpretado.
- [ ] `fraud_model.joblib` guardado.
- [ ] Código commiteado en GitHub.

Si todo está ✅ → **listo para el Manual 04B: Fine-tuning local (PEFT) o el Manual 05 (RAG).**

---

## 12. Troubleshooting

| Problema | Causa | Solución |
|---|---|---|
| `MemoryError` en el entrenamiento | Muestra muy grande para Cloud Shell | Baja el muestreo (`RAND() < 0.02`), usa un notebook de Vertex AI, o tu PC local. |
| BQML "Quota/billing" al entrenar | Modelo iterativo costoso | Usa `LOGISTIC_REG` (incluido); el XGBoost hazlo en Python (gratis). |
| `shap` tarda mucho o falla | Cálculo pesado | Reduce la muestra SHAP (`min(1000, ...)`). |
| AUC-PR sospechosamente perfecto (1.0) | Posible fuga de datos | Revisa que no entró `is_flagged_fraud` ni `step`. |
| `xgboost` no instala | Dependencias | `pip install --user xgboost`; en local usa conda si falla. |
| `bq extract` / Export falla | Tabla muy grande para un archivo | Usa comodín: `.../train_sample_*.csv`. |
| Reporte con recall bajo | Umbral o desbalanceo | Ajusta umbral; sube `scale_pos_weight`; revisa features. |
| Vertex AI Workbench sigue cobrando | La instancia quedó encendida | Workbench → instancia → **STOP** al terminar. |

---

## 13. Glosario

- **CRISP-DM:** metodología de 6 fases para proyectos de datos.
- **Clasificación binaria:** predecir una de dos clases (fraude / no fraude).
- **Clases desbalanceadas:** una clase rarísima frente a la otra.
- **Accuracy:** % de aciertos — **engaña** con desbalanceo.
- **Precision / Recall / F1 / AUC-PR:** métricas correctas para fraude.
- **Matriz de confusión:** TP, FP, FN, TN.
- **Fuga de datos (leakage):** usar info no disponible en inferencia o proxy de la etiqueta.
- **scale_pos_weight / class_weight:** dar más peso a la clase minoritaria.
- **SMOTE:** técnica de oversampling sintético (imbalanced-learn).
- **Umbral (threshold):** punto de corte de probabilidad para decidir la clase.
- **XGBoost:** modelo de ensemble (gradient boosting) potente y estándar.
- **SHAP:** método para explicar predicciones (qué feature pesó y cuánto).
- **BigQuery ML:** entrenar modelos con SQL dentro de BigQuery.
- **Vertex AI Workbench:** notebooks Jupyter gestionados en GCP (la vía visual para Python/ML).

---

> **⬅️ Anterior:** [Manual 03 — Orquestación con Airflow](./03_orquestacion_airflow.md)
> **➡️ Siguiente:** Manual 04B — Fine-tuning local (PEFT) _(en construcción)_ · luego Manual 05 — RAG
