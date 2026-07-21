# Manual 00 — Configuración del entorno en la nube

> **Objetivo:** Dejar listo TODO el entorno de trabajo en la nube para construir **FraudShield** (plataforma de detección de fraude bancario), sin instalar bases de datos ni herramientas pesadas en tu PC. Al terminar tendrás: una cuenta de Google Cloud con facturación y alertas, tu "centro de operaciones" en Cloud Shell, el proyecto creado, las APIs habilitadas, un repositorio en GitHub conectado, y la estructura de carpetas del proyecto.
>
> **Tiempo estimado:** 2–3 horas.
> **Lo único que necesitas en tu PC:** un navegador web (Chrome recomendado) y una cuenta de Google (Gmail).

> ⚠️ **Métodos vigentes a jul-2026** (ver [§15 Fuentes](#15-fuentes)). Donde una consola pueda haber cambiado, te doy también la **ruta por menú** y el **comando CLI**, más estables.
>
> 🔀 **Este proyecto es 100% GCP.** El entorno y la práctica de **AWS** viven ahora en el proyecto hermano **[`aws-banking-copilot/`](../../aws-banking-copilot/manuales/00_entorno_aws.md)** (cuenta AWS, IAM Identity Center, Bedrock, Guardrails). Aquí no montas AWS; solo dejamos un **mapa mental GCP↔AWS** para entrevistas (§11B).

---

## 🖱️ / ⌨️ Cómo leer este manual (UI + CLI)

Este manual está escrito en formato **doble camino**, pensado para que vayas tranquilo aunque el CLI aún se te haga cuesta arriba:

- 🖱️ **Por la Consola (UI):** clic por clic en la consola web de GCP (`console.cloud.google.com`). Es lo más intuitivo: *ves* lo que haces.
- ⌨️ **Equivalente en CLI:** el mismo resultado con un comando en **Cloud Shell**. Es lo que se *espera* que domines en una entrevista de Ingeniero ML; te da velocidad. Está al lado como referencia y "músculo".

👉 **Puedes completar el manual entero solo con la UI.** Cuando un paso sea *inevitablemente* de terminal (crear la estructura de carpetas, clonar el repo), te doy también la forma más visual posible (el editor gráfico de Cloud Shell o VS Code).

💡 **Consejo para semi-junior:** haz cada paso primero por la UI para entenderlo. Cuando ya funcione, repítelo por CLI en una segunda pasada. Así aprendes ambos sin frustrarte.

---

## 📋 Tabla de contenido

1. [Conceptos previos (lee esto primero)](#1-conceptos-previos)
2. [Crear y configurar la cuenta de Google Cloud](#2-cuenta-gcp)
3. [Crear el proyecto FraudShield](#3-crear-proyecto)
4. [Configurar facturación y alertas de presupuesto](#4-presupuesto)
5. [Conocer y configurar Cloud Shell (tu terminal)](#5-cloud-shell)
6. [Configurar gcloud (CLI) y variables](#6-gcloud)
7. [Habilitar las APIs necesarias](#7-apis)
8. [Crear cuenta en GitHub y el repositorio](#8-github)
9. [Conectar Cloud Shell con GitHub](#9-conectar-github)
10. [Crear la estructura del proyecto](#10-estructura)
11. [Primer commit](#11-commit)
11B. [Entorno local y nota multi-cloud](#11b-entorno-local-y-nota-multi-cloud)
12. [✅ Checklist final del Manual 00](#12-checklist)
13. [🛟 Solución de problemas](#13-troubleshooting)
14. [📖 Glosario](#14-glosario)
15. [🔗 Fuentes (verificadas jul-2026)](#15-fuentes)

---

## 1. Conceptos previos

Antes de tocar nada, entiende **qué es cada cosa**. Esto te evitará confusión todo el proyecto.

📖 **Google Cloud Platform (GCP):** El conjunto de servicios en la nube de Google (almacenamiento, bases de datos, cómputo, IA). Es uno de los 3 grandes (junto a AWS y Azure) y es el "plus" que pide Ceiba.

📖 **Consola web (UI):** el sitio `console.cloud.google.com` donde administras todo con clics, menús y botones. Es tu tablero de control visual.

📖 **Proyecto (GCP Project):** Un contenedor lógico donde viven todos tus recursos (datos, máquinas, APIs). Todo en GCP pertenece a un proyecto. Cada proyecto tiene un **Project ID** único en el mundo.

📖 **Facturación (Billing):** Una cuenta de pago asociada a uno o más proyectos. Aunque uses el free tier, GCP exige una tarjeta para verificar identidad. **No te cobran sin avisar** si configuras alertas.

📖 **Cloud Shell:** Una máquina Linux temporal y gratuita que Google te da **dentro del navegador**, con todas las herramientas (gcloud, python, git, etc.) ya instaladas. Es tu "computador en la nube". Tiene un disco persistente de 5 GB en `$HOME`.

📖 **gcloud:** La herramienta de línea de comandos (CLI) para controlar GCP desde la terminal. Ya viene instalada en Cloud Shell. **Todo lo que hace gcloud, casi siempre también se puede hacer con clics en la consola** — por eso este manual te muestra las dos formas.

📖 **API:** Para usar cada servicio de GCP (BigQuery, Cloud Storage, etc.) primero debes "habilitar su API" en tu proyecto. Es como activar un interruptor.

📖 **Data Lake vs Data Warehouse:**
- **Data Lake** = almacén de archivos crudos en cualquier formato (CSV, JSON, PDF). En GCP es **Cloud Storage**. Barato, flexible.
- **Data Warehouse (DW)** = base de datos analítica con datos ya estructurados y consultables con SQL. En GCP es **BigQuery**. Optimizado para análisis de grandes volúmenes.

💡 **El flujo que construirás:** transacciones y quejas crudas → Data Lake (Cloud Storage) → Data Warehouse (BigQuery) → transformación (features de fraude) → modelo de detección de fraude + consultas semánticas (RAG) → despliegue.

---

## 2. Cuenta GCP

> Esta sección es **100% por UI** (no hay otra forma de crear la cuenta).

### Paso 2.1 — Verifica tu cuenta de Google
Necesitas una cuenta de Google (Gmail). Si ya tienes `danielcaro317@gmail.com`, úsala.

### Paso 2.2 — Activa el free trial de Google Cloud
1. Abre el navegador y ve a: **https://cloud.google.com/**
2. Haz clic en **"Comenzar gratis"** (Get started for free), arriba a la derecha.
3. Inicia sesión con tu cuenta de Google.
4. **Paso 1 del formulario:** elige tu país (**Colombia**), acepta los términos. Clic en **Continuar**.
5. **Paso 2:** selecciona el tipo de cuenta:
   - Tipo de cuenta: **Individual** (Particular).
   - Ingresa tu nombre y dirección.
6. **Verificación de tarjeta:** ingresa una tarjeta de crédito/débito.

   💡 **¿Por qué piden tarjeta?** Solo para verificar que eres humano (evitar abuso). En el free trial **no se cobra automáticamente** al acabar el crédito: la cuenta se pausa y te pide confirmación para pasar a pago. Verás un cargo temporal de ~USD 1 que se reversa.
7. Clic en **"Iniciar mi prueba gratuita"**.

### ✅ Checkpoint 2
Deberías llegar a la **consola de GCP** (`https://console.cloud.google.com/`) y ver un banner que dice algo como *"Te quedan USD 300 en créditos y 90 días"*. Si lo ves, ¡vas bien!

🛟 *Si la tarjeta es rechazada:* prueba otra tarjeta (a veces tarjetas virtuales o algunas débito fallan). Debe permitir cargos internacionales.

---

## 3. Crear proyecto

Por defecto Google te crea un proyecto llamado "My First Project". Vamos a crear uno propio y limpio para FraudShield.

🖱️ **Por la Consola (UI):**
1. En la consola, arriba a la izquierda (al lado del logo "Google Cloud"), haz clic en el **selector de proyecto** (el menú desplegable que muestra el proyecto actual).
2. En la ventana que abre, clic en **"Proyecto nuevo"** (New Project), arriba a la derecha.
3. Llena:
   - **Nombre del proyecto:** `FraudShield`
   - **Project ID:** Google sugiere uno (ej. `fraudshield-461512`). **Anótalo**, lo usarás MUCHÍSIMO. Si quieres, edítalo a algo como `fraudshield-tu-nombre` (debe ser único globalmente, solo minúsculas, números y guiones).
   - **Ubicación:** déjalo "Sin organización" (No organization).
4. Clic en **"Crear"**. Espera ~30 segundos.
5. Vuelve al selector de proyecto (arriba) y elige **FraudShield**. Confirma que arriba aparece "FraudShield" como proyecto activo.

⌨️ **Equivalente en CLI (Cloud Shell — lo verás en la sección 5):**
```bash
gcloud projects create fraudshield-tu-nombre --name="FraudShield"
gcloud config set project fraudshield-tu-nombre
```

### ✅ Checkpoint 3
Anota tu **Project ID** aquí para no olvidarlo:
```
MI PROJECT ID = ____________________________
```
💡 **Project ID vs Project Name:** El *Name* ("FraudShield") es para humanos; el *ID* (`fraudshield-461512`) es el identificador real que usan los comandos. Siempre usa el **ID**.

---

## 4. Presupuesto

⚠️ **Este paso NO es opcional.** Te protege de cobros inesperados. Se hace **por UI**.

🖱️ **Por la Consola (UI):**
1. En la consola, usa la barra de búsqueda de arriba y escribe **"Budgets & alerts"** (Presupuestos y alertas). Entra.
   - (Ruta de menú: ☰ → Billing → Budgets & alerts).
2. Clic en **"Crear presupuesto"** (Create budget).
3. **Scope (Alcance):**
   - Name: `Presupuesto-FraudShield`
   - Projects: selecciona **FraudShield**.
   - Deja el resto por defecto. **Next**.
4. **Amount (Monto):**
   - Budget type: **Specified amount**.
   - Target amount: `50` (USD). 💡 Es solo el umbral de alerta; no es un límite de gasto, es para que te avisen.
   - **Next**.
5. **Actions (Alertas):** deja los umbrales por defecto (50%, 90%, 100%). Marca la casilla **"Email alerts to billing admins and users"**.
6. Clic en **"Finish"** (Finalizar).

### ✅ Checkpoint 4
Verás tu presupuesto "Presupuesto-FraudShield" en la lista. Ahora recibirás un correo si el gasto del proyecto se acerca a USD 50.

💡 Como casi todo lo que harás cae en el free tier, lo normal es que gastes **USD 0–5** en todo el proyecto (el costo real aparece si dejas Cloud Composer encendido muchos días; el Manual 03 te enseña a apagarlo).

---

## 5. Cloud Shell

Cloud Shell será tu terminal principal durante TODO el proyecto. Aunque uses la UI para casi todo, hay pasos (clonar el repo, correr scripts) que viven aquí. Tranquilo: te acompaño clic a clic.

### Paso 5.1 — Abrir Cloud Shell
1. En la consola de GCP, arriba a la derecha, busca el ícono de terminal: **`>_`** ("Activate Cloud Shell"). Haz clic.
2. Se abre un panel en la parte inferior. La primera vez tarda ~1 min en aprovisionar tu máquina y puede pedirte **"Authorize"** — acepta.
3. Cuando veas un prompt como `tu_usuario@cloudshell:~ (fraudshield-461512)$` ¡ya estás dentro de tu Linux en la nube!

💡 **¿Nunca has usado una terminal?** Una terminal es solo una caja donde escribes una orden (comando) y presionas Enter. No puede "romper" tu PC; estás en una máquina desechable de Google. Si algo sale raro, ciérrala y ábrela de nuevo.

### Paso 5.2 — Familiarízate (ejecuta estos comandos)
Copia y pega uno por uno (Enter después de cada uno):

```bash
whoami            # Ver el usuario en el que estás
pwd               # Ver el directorio actual (tu home persistente)
python3 --version # Python ya viene instalado
gcloud --version  # gcloud ya viene instalado
git --version     # git ya viene instalado
```

💡 **Lo importante:** todo lo que guardes en tu carpeta `$HOME` (`/home/tu_usuario`) **persiste** entre sesiones (5 GB). Lo que instales fuera de ahí se borra cuando la sesión expira (tras ~1 h de inactividad o 12 h de uso). Por eso trabajaremos siempre dentro de `$HOME`.

### Paso 5.3 — El editor de código (Cloud Shell Editor) — ¡tu mejor amigo visual!
Cloud Shell incluye un **editor visual idéntico a VS Code**. Clic en el botón **"Open Editor"** (ícono de lápiz) en la barra de Cloud Shell. Ahí puedes:
- Ver tus carpetas y archivos en un panel lateral (como el explorador de Windows).
- Crear carpetas/archivos con clic derecho → *New Folder* / *New File*.
- Editar y pegar texto con el mouse (mucho más cómodo que la terminal para archivos largos).
- Volver a la terminal con **"Open Terminal"**.

👉 Cada vez que un paso diga "crea este archivo", puedes hacerlo aquí con el mouse en lugar de la terminal.

### ✅ Checkpoint 5
Los 5 comandos del paso 5.2 muestran versiones sin errores. Sabes abrir el "Open Editor".

---

## 6. gcloud

Le decimos a gcloud cuál es tu proyecto por defecto, para no repetirlo en cada comando.

🖱️ **Por la Consola (UI):**
- El "proyecto por defecto" en la UI es simplemente el que tienes **seleccionado en el selector de proyecto** (arriba, junto al logo). Si arriba dice **FraudShield**, ya estás en el proyecto correcto — no hay que hacer nada más.
- La **región** en la UI no se fija globalmente: la eliges en un desplegable cada vez que creas un recurso (bucket, dataset, etc.). En este proyecto siempre elegirás **`us-central1`**.

⌨️ **Equivalente en CLI (Cloud Shell):** fija proyecto y región para que la terminal no te los pregunte:
```bash
# Reemplaza <TU_PROJECT_ID> por el que anotaste en el Checkpoint 3
gcloud config set project <TU_PROJECT_ID>
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
gcloud config list          # verifica proyecto, región y cuenta

# Guardar tu Project ID en una variable reutilizable (y que se cargue siempre):
export PROJECT_ID=$(gcloud config get-value project)
echo 'export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)' >> ~/.bashrc
echo "Mi proyecto es: $PROJECT_ID"
```

💡 **¿Por qué us-central1 y no Suramérica?** `southamerica-east1` (São Paulo) existe pero es más caro y a veces no tiene todos los servicios/free tier. Para aprender, `us-central1` (Iowa) es el estándar. La latencia no te afectará.

### ✅ Checkpoint 6
En la UI, arriba dice **FraudShield**. En CLI, `gcloud config list` muestra tu proyecto y región, y `echo $PROJECT_ID` muestra tu Project ID.

---

## 7. APIs

Cada servicio necesita su API habilitada (activar el "interruptor"). Son 10.

🖱️ **Por la Consola (UI):**
1. Menú **☰** → **APIs & Services** → **Library** (Biblioteca).
2. En el buscador escribe el nombre del servicio (ej. **BigQuery API**) → clic en el resultado → botón azul **ENABLE** (Habilitar).
3. Repite para cada uno: *BigQuery API, Cloud Storage API, Cloud Composer API, Vertex AI API, Cloud Run Admin API, Artifact Registry API, Cloud Build API, IAM API, Cloud SQL Admin API, Secret Manager API.*

💡 **Atajo mental:** no tienes que habilitarlas todas hoy. Cada vez que entres por primera vez a un servicio en la consola (ej. BigQuery), si su API no está activa, la propia consola te muestra un botón **ENABLE**. Puedes ir habilitando "según necesites". Pero hacerlo de una vez por CLI es más cómodo.

⌨️ **Equivalente en CLI (Cloud Shell) — habilita las 10 de un golpe:**
```bash
gcloud services enable \
  bigquery.googleapis.com \
  storage.googleapis.com \
  composer.googleapis.com \
  aiplatform.googleapis.com \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  iam.googleapis.com \
  sqladmin.googleapis.com \
  secretmanager.googleapis.com
```

💡 **Qué activaste:**
- `bigquery` → Data Warehouse.
- `storage` → Data Lake (Cloud Storage).
- `composer` → Airflow gestionado.
- `aiplatform` → Vertex AI (ML e IA generativa).
- `run` → Cloud Run (despliegue de la API).
- `artifactregistry` → guardar imágenes Docker.
- `cloudbuild` → construir imágenes.
- `iam` → permisos.
- `sqladmin` → Cloud SQL (para pgvector en el RAG).
- `secretmanager` → guardar claves secretas (API keys).

**Verificar** — UI: **APIs & Services → Enabled APIs & services** (deben aparecer en la lista). CLI:
```bash
gcloud services list --enabled --filter="bigquery OR storage OR aiplatform" --format="value(config.name)"
```

### ✅ Checkpoint 7
Las 10 APIs aparecen como habilitadas (en la lista de la UI o sin error en el CLI).

---

## 8. GitHub

Todo tu código vivirá en GitHub. Es tu portafolio. Esta sección es **100% por UI**.

### Paso 8.1 — Crear cuenta (si no tienes)
1. Ve a **https://github.com/** → **Sign up**.
2. Usa tu correo, crea un usuario profesional (ej. `danielcaro-data`). Verifica el correo.

### Paso 8.2 — Crear el repositorio
1. En GitHub, arriba a la derecha, clic en **"+"** → **"New repository"**.
2. Llena:
   - **Repository name:** `fraudshield`
   - **Description:** `Plataforma cloud de Datos + IA (GCP): ELT, ML y RAG sobre datos financieros.`
   - **Public** (queremos que el reclutador lo vea).
   - Marca **"Add a README file"**.
   - **Add .gitignore:** elige la plantilla **Python**.
   - License: **MIT** (opcional).
3. Clic en **"Create repository"**.

### ✅ Checkpoint 8
Tienes un repo en `https://github.com/<tu_usuario>/fraudshield` con un README y un `.gitignore`.

---

## 9. Conectar GitHub

Necesitamos traer el repo a tu entorno de trabajo. Tienes dos caminos según dónde te sientas más cómodo.

🖱️ **Opción A — VS Code en tu PC (la más visual):**
1. Instala **VS Code** (https://code.visualstudio.com/) y **Git** (https://git-scm.com/download/win) — ver Parte B.
2. En VS Code: **Ctrl+Shift+P** → escribe `Git: Clone` → pega la URL `https://github.com/<tu_usuario>/fraudshield.git` → elige carpeta.
3. VS Code te pedirá iniciar sesión en GitHub con un botón (**Sign in with browser**) — sin tokens manuales. A partir de ahí, *commit* y *push* se hacen con botones en el panel **Source Control** (ícono de ramas a la izquierda).

⌨️ **Opción B — Cloud Shell (CLI, la del resto de manuales):**
```bash
# 1) Tu identidad de Git
git config --global user.name "<Tu Nombre>"
git config --global user.email "<tu_correo_github>"

# 2) GitHub ya no acepta contraseña: crea un Personal Access Token (PAT)
#    En GitHub: foto → Settings → Developer settings → Personal access tokens →
#    Tokens (classic) → Generate new token (classic) → scope "repo" → copia el ghp_...

# 3) Clonar
cd ~
git clone https://github.com/<tu_usuario>/fraudshield.git
cd fraudshield
#   Username: tu usuario | Password: pega el token ghp_... (NO tu contraseña)

# 4) Que recuerde el token para no repetirlo
git config --global credential.helper store
```

💡 **Recomendación para semi-junior:** usa la **Opción A (VS Code)** para el día a día — clonar, commit y push con botones es mucho menos frustrante. Deja Cloud Shell para correr los scripts. Ambas trabajan sobre el mismo repo de GitHub.

### ✅ Checkpoint 9
Tienes la carpeta `fraudshield` (en tu PC vía VS Code, o en Cloud Shell) con `README.md` y `.gitignore` dentro.

---

## 10. Estructura

Creamos el esqueleto de carpetas del proyecto dentro de `fraudshield`.

🖱️ **Por la UI (Cloud Shell Editor o VS Code):**
1. Abre **Open Editor** (Cloud Shell) o el explorador de VS Code.
2. Clic derecho sobre la carpeta `fraudshield` → **New Folder** → crea una por una:
   `extract`, `dbt_project`, `dags`, `notebooks`, `ml`, `finetune`, `rag`, `agents`, `eval`, `api`, `frontend`, `infra`, `docs`, `config`.
3. (Opcional) dentro de cada una, clic derecho → **New File** → `.gitkeep` (un archivo vacío para que Git conserve la carpeta).

⌨️ **Equivalente en CLI (Cloud Shell) — mucho más rápido:**
```bash
cd ~/fraudshield
mkdir -p extract dbt_project dags notebooks ml finetune rag agents eval api frontend infra docs config .github/workflows
touch extract/.gitkeep dbt_project/.gitkeep dags/.gitkeep notebooks/.gitkeep \
      ml/.gitkeep finetune/.gitkeep rag/.gitkeep agents/.gitkeep eval/.gitkeep \
      api/.gitkeep frontend/.gitkeep infra/.gitkeep docs/.gitkeep config/.gitkeep
```
💡 Carpetas del **super-proyecto** (fusión Ceiba + Proxify): `finetune/` (LoRA/QLoRA local), `agents/` (Agente de Fraude con LangGraph), `eval/` (evaluación RAGAS), `infra/` (Terraform/IaC).

### Paso 10.3 — Mejorar el README del proyecto
Abre `README.md` en el editor visual y reemplaza su contenido por esto (o usa el `cat >` de abajo en la terminal):

```markdown
# FraudShield 🛡️🏦

Plataforma cloud-native de **detección de fraude bancario (Datos + IA)** para un departamento antifraude, construida en **Google Cloud Platform**.

## Caso de uso
Analiza millones de transacciones bancarias para detectar fraude, y permite a los analistas hacer **consultas semánticas y cualitativas** (en lenguaje natural) sobre narrativas de casos y quejas de clientes.

## Arquitectura
Kaggle/CFPB (transacciones + quejas) → Cloud Storage (Data Lake) → BigQuery (Data Warehouse) → dbt (ELT, features de fraude) → Airflow (orquestación) → Vertex AI (modelo de detección de fraude + RAG) → Cloud Run (API de scoring + chat) → React (dashboard antifraude).

## Stack
Python · SQL · BigQuery · dbt · Apache Airflow (Cloud Composer) · scikit-learn / XGBoost · Vertex AI · RAG (embeddings + vector search) · FastAPI · Docker · Cloud Run · React.

## Estructura
- `extract/` — ingesta de transacciones y quejas al Data Lake
- `dbt_project/` — transformaciones ELT y features de fraude
- `dags/` — pipelines de Airflow
- `notebooks/` — EDA y modelado de detección de fraude
- `ml/` — entrenamiento del modelo de fraude
- `finetune/` — fine-tuning local (LoRA/QLoRA)
- `rag/` — asistente de consultas semánticas/cualitativas (RAG)
- `agents/` — Agente Investigador de Fraude (LangGraph)
- `eval/` — evaluación de RAG/LLM (RAGAS)
- `api/` — API de scoring + chat (FastAPI)
- `frontend/` — dashboard antifraude (React)
- `infra/` — infraestructura como código (Terraform)
- `docs/` — documentación y decisiones de arquitectura

## Estado
🚧 En construcción — siguiendo metodología CRISP-DM.
```

### ✅ Checkpoint 10
El explorador de archivos (UI) o `ls` (CLI) dentro de `fraudshield` muestra todas las carpetas.

---

## 11. Commit

Guarda todo en GitHub (subir tus cambios).

🖱️ **Por la UI (VS Code / Cloud Shell Editor):**
1. Ve al panel **Source Control** (ícono de ramas, izquierda).
2. Verás la lista de archivos nuevos. Escribe un mensaje arriba: `Estructura inicial del proyecto y entorno cloud configurado`.
3. Clic en **✓ Commit** → luego **Sync Changes** / **Push** (la flechita ↑).

⌨️ **Equivalente en CLI (Cloud Shell):**
```bash
cd ~/fraudshield
git add .
git commit -m "Estructura inicial del proyecto y entorno cloud configurado"
git push origin main
```
💡 Si tu rama se llama `master` en vez de `main`, usa `git push origin master`. Verifica con `git branch`.

### ✅ Checkpoint 11
Recarga `https://github.com/<tu_usuario>/fraudshield` en el navegador: deben aparecer todas las carpetas y el nuevo README. 🎉

---

## 11B. Entorno local y nota multi-cloud

> 🔀 **Multi-cloud, ahora en dos proyectos.** El setup y la práctica de **AWS** (cuenta, IAM Identity Center, CloudShell, Bedrock, Guardrails) viven en el proyecto hermano **[`aws-banking-copilot/`](../../aws-banking-copilot/manuales/00_entorno_aws.md)** — mucho más completo que la vieja "Parte B". Aquí dejamos solo: (a) el **mapa mental GCP↔AWS** para entrevistas, y (b) tu **entorno local** (Ollama/Docker/GPU) para desarrollar RAG, agentes y fine-tuning **gratis**.
>
> 💡 Esta parte **no bloquea** el Manual 01.

💡 **Equivalencias mentales GCP ↔ AWS** (memorízalas, son oro en entrevista):

| Necesidad | GCP | AWS |
|---|---|---|
| Almacenamiento de objetos (Data Lake) | Cloud Storage | **S3** |
| Data Warehouse | BigQuery | **Redshift** / Athena |
| Contenedor serverless | Cloud Run | **App Runner / ECS Fargate** |
| Funciones serverless | Cloud Functions | **Lambda** |
| Plataforma ML | Vertex AI | **SageMaker** |
| LLMs gestionados | Vertex AI / Model Garden | **Bedrock** |
| Secretos | Secret Manager | **Secrets Manager** |
| Permisos | IAM | **IAM** |
| Registro de imágenes | Artifact Registry | **ECR** |
| Kubernetes gestionado | GKE | **EKS** |

> 👉 **Para el hands-on de AWS** (crear la cuenta, IAM Identity Center, CloudShell, habilitar modelos Bedrock, Guardrails) ve al **[Manual 00 del proyecto AWS](../../aws-banking-copilot/manuales/00_entorno_aws.md)**. Está actualizado (jul-2026) y usa los métodos vigentes (nada de access keys de larga duración).

### 11B.1 — Entorno LOCAL (tu PC: RTX 4070 Super, Ryzen 7900, 64 GB)
Esto lo instalas **en tu computador**, no en Cloud Shell. Te servirá para desarrollar RAG/agentes/fine-tuning gratis.

1. **VS Code** — https://code.visualstudio.com/ + extensiones: Python, Jupyter, Docker, GitLens.
2. **Git** — https://git-scm.com/download/win (configura `user.name`/`user.email` igual que en Cloud Shell).
3. **Docker Desktop** — https://www.docker.com/products/docker-desktop/ (para Airflow/MLflow/contenedores locales).
4. **Miniconda o uv** (gestor de entornos Python):
   - uv (rápido): https://docs.astral.sh/uv/
5. **Ollama** (LLMs locales en tu GPU, gratis) — https://ollama.com/download :
   ```powershell
   # En PowerShell, tras instalar Ollama:
   ollama --version
   ollama pull llama3.1:8b        # un LLM general
   ollama pull nomic-embed-text   # modelo de embeddings para el RAG
   ollama run llama3.1:8b "Hola, ¿funcionas?"
   ```
   💡 Tu RTX 4070 Super (12 GB VRAM) corre modelos de 7–8B sin problema → desarrollas el RAG y los agentes **sin gastar API**.
6. **(Para fine-tuning, Manual 04B)** verifica que tu GPU es visible para PyTorch (lo instalarás en su momento):
   ```powershell
   # más adelante, dentro de tu entorno:
   # python -c "import torch; print(torch.cuda.is_available())"  -> debe dar True
   ```
7. **Clona el repo también en local** (para trabajar local cuando convenga):
   ```powershell
   git clone https://github.com/<tu_usuario>/fraudshield.git
   ```

### ✅ Checkpoint 11B
- En tu PC: VS Code, Git, Docker Desktop instalados.
- `ollama run llama3.1:8b "test"` responde usando tu GPU.
- (AWS) → se valida en el [proyecto AWS](../../aws-banking-copilot/manuales/00_entorno_aws.md), no aquí.

🛟 *Ollama no usa la GPU:* actualiza drivers NVIDIA; Ollama detecta CUDA automáticamente. *Docker Desktop no arranca:* habilita WSL2/virtualización en BIOS.

---

## 12. Checklist

Marca todo antes de pasar al Manual 01:

**GCP (obligatorio para Manual 01):**
- [ ] Cuenta GCP activa con crédito gratis visible.
- [ ] Proyecto **FraudShield** creado y seleccionado; tengo anotado mi **Project ID**.
- [ ] Presupuesto con alertas configurado.
- [ ] Cloud Shell abre y los comandos de versión funcionan; sé usar "Open Editor".
- [ ] Proyecto activo en la UI (arriba dice FraudShield) / `gcloud config list` correcto.
- [ ] Las 10 APIs habilitadas sin error.
- [ ] Repo `fraudshield` creado en GitHub y clonado (VS Code o Cloud Shell).
- [ ] Estructura de carpetas creada (incluye `agents/ finetune/ eval/ infra/`).
- [ ] Primer commit visible en GitHub.

**Entorno local + multi-cloud (puede hacerse ahora o antes de los Manuales 04B/05):**
- [ ] Entiendo las equivalencias **GCP↔AWS** (§11B).
- [ ] Entorno local listo (VS Code, Git, Docker Desktop).
- [ ] Ollama corriendo en tu GPU (LLM + embeddings).
- [ ] (AWS hands-on) lo haré en el proyecto **[aws-banking-copilot](../../aws-banking-copilot/)** cuando toque.

Si lo obligatorio está ✅ → **estás listo para el Manual 01: Ingesta de datos y Data Lake.**

---

## 13. Troubleshooting

| Problema | Causa probable | Solución |
|---|---|---|
| "Billing account not found" al habilitar APIs | El proyecto no tiene billing vinculado | Consola → Billing → vincula la cuenta de facturación al proyecto FraudShield. |
| Cloud Shell dice "session expired" | Inactividad > 1 h | Solo reábrelo; tu `$HOME` persiste. Vuelve a hacer `export PROJECT_ID=...` si no lo pusiste en `.bashrc`. |
| `git push` pide usuario y rechaza contraseña | GitHub no acepta contraseña | Usa el **Personal Access Token** como "password", o cambia a la Opción A (VS Code con login por navegador). |
| "Permission denied" en gcloud | Cuenta sin permisos / proyecto equivocado | Verifica el selector de proyecto (UI) o `gcloud config set project <ID>`. |
| No aparece el ícono de Cloud Shell | Navegador/extensión | Usa Chrome, desactiva bloqueadores, recarga la consola. |
| El botón ENABLE de una API no aparece | Ya está habilitada | Revisa en APIs & Services → Enabled APIs. |
| Token de GitHub "expirado" | Pasaron los 90 días | Genera uno nuevo y vuelve a hacer push. |

---

## 14. Glosario

- **GCP:** Google Cloud Platform, la nube de Google.
- **Consola (UI):** el sitio web para administrar GCP con clics.
- **Project ID:** identificador único global de tu proyecto en GCP.
- **Billing account:** cuenta de facturación; necesaria aunque uses free tier.
- **Free tier / Free trial:** créditos gratis (USD 300/90 días) + servicios siempre gratis con límites.
- **Cloud Shell:** terminal Linux gratuita en el navegador con herramientas preinstaladas.
- **Open Editor:** el editor visual (tipo VS Code) integrado en Cloud Shell.
- **gcloud:** CLI para administrar GCP.
- **API:** interfaz que se debe "habilitar" para usar cada servicio.
- **Data Lake:** almacén de archivos crudos (Cloud Storage).
- **Data Warehouse:** base analítica SQL para grandes volúmenes (BigQuery).
- **Repositorio (repo):** carpeta versionada de tu código en GitHub.
- **PAT (Personal Access Token):** token que reemplaza la contraseña para autenticarte en GitHub por CLI.
- **Región/Zona:** ubicación física de los servidores donde corren tus recursos.
- **`.gitignore`:** archivo que le dice a Git qué NO subir (ej. credenciales, temporales).

---

## 15. Fuentes

Verificadas el **21 de julio de 2026** (si algo cambia, aquí está la fuente oficial):

- Prueba gratuita de Google Cloud (USD 300 / 90 días) — [cloud.google.com/free](https://cloud.google.com/free)
- Presupuestos y alertas (Budgets) — [cloud.google.com/billing/docs/how-to/budgets](https://cloud.google.com/billing/docs/how-to/budgets)
- Cloud Shell y editor — [cloud.google.com/shell/docs](https://cloud.google.com/shell/docs)
- Habilitar APIs (`gcloud services enable`) — [cloud.google.com/sdk/gcloud/reference/services/enable](https://cloud.google.com/sdk/gcloud/reference/services/enable)
- Autenticación en GitHub (token/`gh`/navegador) — [docs.github.com/authentication](https://docs.github.com/en/authentication)

🔁 Setup equivalente en AWS → [proyecto aws-banking-copilot, Manual 00](../../aws-banking-copilot/manuales/00_entorno_aws.md).

---

> **➡️ Siguiente:** [Manual 01 — Ingesta de datos y Data Lake](./01_ingesta_datos_y_data_lake.md)
