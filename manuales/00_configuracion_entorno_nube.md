# Manual 00 — Configuración del entorno en la nube

> **Objetivo:** Dejar listo TODO el entorno de trabajo en la nube para construir **FraudShield** (plataforma de detección de fraude bancario), sin instalar bases de datos ni herramientas pesadas en tu PC. Al terminar tendrás: una cuenta de Google Cloud con facturación y alertas, tu "centro de operaciones" en Cloud Shell, el proyecto creado, las APIs habilitadas, un repositorio en GitHub conectado, y la estructura de carpetas del proyecto.
>
> **Tiempo estimado:** 2–3 horas.
> **Lo único que necesitas en tu PC:** un navegador web (Chrome recomendado) y una cuenta de Google (Gmail).

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
11B. [Parte B — Multi-cloud (AWS) y entorno local 🆕](#11b-parte-b--multi-cloud-aws-y-entorno-local)
12. [✅ Checklist final del Manual 00](#12-checklist)
13. [🛟 Solución de problemas](#13-troubleshooting)
14. [📖 Glosario](#14-glosario)

---

## 1. Conceptos previos

Antes de tocar nada, entiende **qué es cada cosa**. Esto te evitará confusión todo el proyecto.

📖 **Google Cloud Platform (GCP):** El conjunto de servicios en la nube de Google (almacenamiento, bases de datos, cómputo, IA). Es uno de los 3 grandes (junto a AWS y Azure) y es el "plus" que pide Ceiba.

📖 **Proyecto (GCP Project):** Un contenedor lógico donde viven todos tus recursos (datos, máquinas, APIs). Todo en GCP pertenece a un proyecto. Cada proyecto tiene un **Project ID** único en el mundo.

📖 **Facturación (Billing):** Una cuenta de pago asociada a uno o más proyectos. Aunque uses el free tier, GCP exige una tarjeta para verificar identidad. **No te cobran sin avisar** si configuras alertas.

📖 **Cloud Shell:** Una máquina Linux temporal y gratuita que Google te da **dentro del navegador**, con todas las herramientas (gcloud, python, git, etc.) ya instaladas. Es tu "computador en la nube". Tiene un disco persistente de 5 GB en `$HOME`.

📖 **gcloud:** La herramienta de línea de comandos (CLI) para controlar GCP desde la terminal. Ya viene instalada en Cloud Shell.

📖 **API:** Para usar cada servicio de GCP (BigQuery, Cloud Storage, etc.) primero debes "habilitar su API" en tu proyecto. Es como activar un interruptor.

📖 **Data Lake vs Data Warehouse:**
- **Data Lake** = almacén de archivos crudos en cualquier formato (CSV, JSON, PDF). En GCP es **Cloud Storage**. Barato, flexible.
- **Data Warehouse (DW)** = base de datos analítica con datos ya estructurados y consultables con SQL. En GCP es **BigQuery**. Optimizado para análisis de grandes volúmenes.

💡 **El flujo que construirás:** transacciones y quejas crudas → Data Lake (Cloud Storage) → Data Warehouse (BigQuery) → transformación (features de fraude) → modelo de detección de fraude + consultas semánticas (RAG) → despliegue.

---

## 2. Cuenta GCP

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

### Paso 3.1 — Crear el proyecto (vía consola web)
1. En la consola, arriba a la izquierda (al lado del logo "Google Cloud"), haz clic en el **selector de proyecto** (el menú desplegable que muestra el proyecto actual).
2. En la ventana que abre, clic en **"Proyecto nuevo"** (New Project), arriba a la derecha.
3. Llena:
   - **Nombre del proyecto:** `FraudShield`
   - **Project ID:** Google sugiere uno (ej. `fraudshield-461512`). **Anótalo**, lo usarás MUCHÍSIMO. Si quieres, edítalo a algo como `fraudshield-tu-nombre` (debe ser único globalmente, solo minúsculas, números y guiones).
   - **Ubicación:** déjalo "Sin organización" (No organization).
4. Clic en **"Crear"**. Espera ~30 segundos.

### Paso 3.2 — Selecciona el proyecto
Vuelve al selector de proyecto (arriba) y elige **FraudShield**. Confirma que arriba aparece "FraudShield" como proyecto activo.

### ✅ Checkpoint 3
Anota tu **Project ID** aquí para no olvidarlo:
```
MI PROJECT ID = ____________________________
```
💡 **Project ID vs Project Name:** El *Name* ("FraudShield") es para humanos; el *ID* (`fraudshield-461512`) es el identificador real que usan los comandos. Siempre usa el **ID**.

---

## 4. Presupuesto

⚠️ **Este paso NO es opcional.** Te protege de cobros inesperados.

### Paso 4.1 — Crear un presupuesto con alertas
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

Cloud Shell será tu terminal principal durante TODO el proyecto.

### Paso 5.1 — Abrir Cloud Shell
1. En la consola de GCP, arriba a la derecha, busca el ícono de terminal: **`>_`** ("Activate Cloud Shell"). Haz clic.
2. Se abre un panel en la parte inferior. La primera vez tarda ~1 min en aprovisionar tu máquina y puede pedirte **"Authorize"** — acepta.
3. Cuando veas un prompt como `tu_usuario@cloudshell:~ (fraudshield-461512)$` ¡ya estás dentro de tu Linux en la nube!

### Paso 5.2 — Familiarízate (ejecuta estos comandos)
Copia y pega uno por uno (Enter después de cada uno):

```bash
# Ver en qué máquina estás
whoami

# Ver el directorio actual (tu home persistente)
pwd

# Ver la versión de Python (ya viene instalado)
python3 --version

# Ver que gcloud está instalado
gcloud --version

# Ver que git está instalado
git --version
```

💡 **Lo importante:** todo lo que guardes en tu carpeta `$HOME` (`/home/tu_usuario`) **persiste** entre sesiones (5 GB). Lo que instales fuera de ahí se borra cuando la sesión expira (tras ~1 h de inactividad o 12 h de uso). Por eso trabajaremos siempre dentro de `$HOME`.

### Paso 5.3 — El editor de código (Cloud Shell Editor)
Cloud Shell incluye un editor visual tipo VS Code. Para abrirlo, clic en el botón **"Open Editor"** (ícono de lápiz) en la barra de Cloud Shell. Podrás editar archivos con interfaz gráfica y volver a la terminal con "Open Terminal".

### ✅ Checkpoint 5
Los 5 comandos del paso 5.2 deben mostrar versiones sin errores. Python 3.x, gcloud, git presentes.

---

## 6. gcloud

Vamos a configurar gcloud para que sepa cuál es tu proyecto por defecto y a guardar variables útiles.

### Paso 6.1 — Configurar el proyecto por defecto
Reemplaza `<TU_PROJECT_ID>` por el ID que anotaste en el Checkpoint 3:

```bash
gcloud config set project <TU_PROJECT_ID>
```
Salida esperada: `Updated property [core/project].`

### Paso 6.2 — Verificar la configuración
```bash
gcloud config list
```
Debe mostrar tu `project = <TU_PROJECT_ID>` y tu cuenta.

### Paso 6.3 — Definir la región
Trabajaremos en una región cercana y económica. Usaremos **`us-central1`** (Iowa) porque tiene todos los servicios y suele estar en free tier. Guárdala como configuración:

```bash
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

💡 **¿Por qué us-central1 y no Suramérica?** `southamerica-east1` (São Paulo) existe pero es más caro y a veces no tiene todos los servicios/free tier. Para aprender, `us-central1` es el estándar. La latencia no te afectará para este proyecto.

### Paso 6.4 — Guardar variables de entorno reutilizables
Para no repetir tu Project ID, lo guardaremos en una variable cada sesión. Ejecuta:

```bash
export PROJECT_ID=$(gcloud config get-value project)
echo "Mi proyecto es: $PROJECT_ID"
```

💡 Para que se cargue automáticamente cada vez que abras Cloud Shell, añádelo a tu `.bashrc`:

```bash
echo 'export PROJECT_ID=$(gcloud config get-value project 2>/dev/null)' >> ~/.bashrc
```

### ✅ Checkpoint 6
`gcloud config list` muestra tu proyecto y región. `echo $PROJECT_ID` muestra tu Project ID.

---

## 7. APIs

Cada servicio necesita su API habilitada. Las habilitamos todas de una vez (esto puede tardar 1–2 min).

### Paso 7.1 — Habilitar las APIs del proyecto
Copia y pega TODO el bloque:

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

### Paso 7.2 — Verificar
```bash
gcloud services list --enabled --filter="bigquery OR storage OR aiplatform" --format="value(config.name)"
```
Deben aparecer las tres en la lista.

### ✅ Checkpoint 7
El comando de habilitación termina con `Operation ... finished successfully` (o sin error). Las APIs aparecen como habilitadas.

---

## 8. GitHub

Todo tu código vivirá en GitHub. Es tu portafolio.

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

Vamos a clonar el repo dentro de Cloud Shell y configurar la autenticación.

### Paso 9.1 — Configurar tu identidad de Git
En Cloud Shell:
```bash
git config --global user.name "<Tu Nombre>"
git config --global user.email "<tu_correo_github>"
```

### Paso 9.2 — Crear un Personal Access Token (PAT) en GitHub
GitHub ya no acepta contraseña para git; necesitas un token.
1. En GitHub: clic en tu foto (arriba derecha) → **Settings** → (abajo) **Developer settings** → **Personal access tokens** → **Tokens (classic)** → **Generate new token (classic)**.
2. **Note:** `cloud-shell-fraudshield`. **Expiration:** 90 days.
3. Marca el scope **`repo`** (completo).
4. **Generate token**. **COPIA el token** (empieza con `ghp_...`) y guárdalo temporalmente en un bloc de notas. Solo se muestra una vez.

### Paso 9.3 — Clonar el repositorio
En Cloud Shell (reemplaza `<tu_usuario>`):
```bash
cd ~
git clone https://github.com/<tu_usuario>/fraudshield.git
cd fraudshield
```
Cuando te pida:
- **Username:** tu usuario de GitHub.
- **Password:** pega el **token** (`ghp_...`), NO tu contraseña.

💡 Para no reescribir el token cada vez, guarda las credenciales:
```bash
git config --global credential.helper store
```
(La próxima vez que hagas push, las guarda en `~/.git-credentials`).

### ✅ Checkpoint 9
`cd ~/fraudshield && ls -la` muestra `README.md` y `.gitignore`. Estás dentro del repo clonado.

---

## 10. Estructura

Vamos a crear el esqueleto de carpetas del proyecto. Dentro de `~/fraudshield`:

### Paso 10.1 — Crear carpetas
```bash
cd ~/fraudshield
mkdir -p extract dbt_project dags notebooks ml finetune rag agents eval api frontend infra docs config .github/workflows
```
💡 Carpetas nuevas del **super-proyecto** (fusión Ceiba + Proxify): `finetune/` (LoRA/QLoRA local), `agents/` (Agente de Fraude con LangGraph), `eval/` (evaluación RAGAS), `infra/` (Terraform/IaC).

### Paso 10.2 — Añadir archivos guía (placeholders) para que las carpetas existan en Git
```bash
touch extract/.gitkeep dbt_project/.gitkeep dags/.gitkeep notebooks/.gitkeep \
      ml/.gitkeep finetune/.gitkeep rag/.gitkeep agents/.gitkeep eval/.gitkeep \
      api/.gitkeep frontend/.gitkeep infra/.gitkeep docs/.gitkeep config/.gitkeep
```

### Paso 10.3 — Crear un README de proyecto mejorado
Abre el editor (botón "Open Editor") o usa este comando para reemplazar el README:

```bash
cat > README.md << 'EOF'
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
EOF
```

### ✅ Checkpoint 10
`ls` dentro de `~/fraudshield` muestra todas las carpetas (extract, dbt_project, dags, etc.).

---

## 11. Commit

Guarda todo en GitHub.

```bash
cd ~/fraudshield
git add .
git commit -m "Estructura inicial del proyecto y entorno cloud configurado"
git push origin main
```
(Si pide usuario/token, ingrésalos; ya quedarán guardados).

💡 Si tu rama se llama `master` en vez de `main`, usa `git push origin master`. Verifica con `git branch`.

### ✅ Checkpoint 11
Recarga `https://github.com/<tu_usuario>/fraudshield` en el navegador: deben aparecer todas las carpetas y el nuevo README. 🎉

---

## 11B. Parte B — Multi-cloud (AWS) y entorno local

> 🆕 **Fusión Proxify:** el cargo de Proxify pide **multi-cloud (AWS/GCP/Azure)** y valora **agentes/fine-tuning** (donde tu GPU local brilla). GCP sigue siendo tu base; AWS lo aprendes **por equivalencia** y lo usarás en el Manual 07 para una demo. El entorno local (Ollama + Docker) lo usarás para desarrollar RAG/agentes/fine-tuning **gratis**.
>
> 💡 Esta Parte B **no bloquea** el Manual 01. Puedes hacerla ahora o cuando llegues a los Manuales 04B/05/07. Pero déjala lista temprano.

### 11B.1 — Cuenta AWS (free tier)
1. Ve a **https://aws.amazon.com/free** → **"Create a Free Account"**.
2. Email, nombre de cuenta, verifica. Tipo **Personal**. Ingresa tarjeta (verificación; free tier 12 meses + servicios siempre gratis).
3. Elige el plan de soporte **Basic (gratis)**.
4. Entra a la **consola AWS** (`https://console.aws.amazon.com/`).

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

### 11B.2 — AWS CloudShell y CLI (sin instalar nada)
Igual que GCP, AWS tiene terminal en el navegador:
1. En la consola AWS, arriba a la derecha, clic en el ícono **CloudShell** (`>_`).
2. Verifica que la CLI está lista:
```bash
aws --version
aws sts get-caller-identity   # muestra tu cuenta
```
💡 No profundizamos en AWS ahora; basta con tener la cuenta y saber abrir su CloudShell. El uso real llega en el Manual 07 (despliegue alternativo en AWS) y Manual 05 (Bedrock como proveedor de LLM opcional).

### 11B.3 — Entorno LOCAL (tu PC: RTX 4070 Super, Ryzen 7900, 64 GB)
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
- Cuenta AWS creada; `aws sts get-caller-identity` funciona en AWS CloudShell.
- En tu PC: VS Code, Git, Docker Desktop instalados.
- `ollama run llama3.1:8b "test"` responde usando tu GPU.

🛟 *Ollama no usa la GPU:* actualiza drivers NVIDIA; Ollama detecta CUDA automáticamente. *Docker Desktop no arranca:* habilita WSL2/virtualización en BIOS.

---

## 12. Checklist

Marca todo antes de pasar al Manual 01:

**GCP (obligatorio para Manual 01):**
- [ ] Cuenta GCP activa con crédito gratis visible.
- [ ] Proyecto **FraudShield** creado y seleccionado; tengo anotado mi **Project ID**.
- [ ] Presupuesto con alertas configurado.
- [ ] Cloud Shell abre y los comandos de versión funcionan.
- [ ] `gcloud config list` muestra mi proyecto y región `us-central1`.
- [ ] Las 10 APIs habilitadas sin error.
- [ ] Repo `fraudshield` creado en GitHub y clonado en Cloud Shell.
- [ ] Estructura de carpetas creada (incluye `agents/ finetune/ eval/ infra/`).
- [ ] Primer commit visible en GitHub.

**Parte B (puede hacerse ahora o más adelante, antes de los Manuales 04B/05/07):**
- [ ] Cuenta AWS creada y AWS CloudShell accesible.
- [ ] Entendí las equivalencias GCP↔AWS.
- [ ] Entorno local listo (VS Code, Git, Docker Desktop).
- [ ] Ollama corriendo en tu GPU (LLM + embeddings).

Si lo obligatorio está ✅ → **estás listo para el Manual 01: Ingesta de datos y Data Lake.**

---

## 13. Troubleshooting

| Problema | Causa probable | Solución |
|---|---|---|
| "Billing account not found" al habilitar APIs | El proyecto no tiene billing vinculado | Consola → Billing → vincula la cuenta de facturación al proyecto FraudShield. |
| Cloud Shell dice "session expired" | Inactividad > 1 h | Solo reábrelo; tu `$HOME` persiste. Vuelve a hacer `export PROJECT_ID=...` si no lo pusiste en `.bashrc`. |
| `git push` pide usuario y rechaza contraseña | GitHub no acepta contraseña | Usa el **Personal Access Token** como "password". |
| "Permission denied" en gcloud | Cuenta sin permisos en el proyecto | Asegúrate de estar en el proyecto correcto: `gcloud config set project <ID>`. |
| No aparece el ícono de Cloud Shell | Navegador/extensión | Usa Chrome, desactiva bloqueadores, recarga la consola. |
| API tarda mucho en habilitar | Normal | Espera 1–2 min; reintenta el comando, es idempotente. |
| Token de GitHub "expirado" | Pasaron los 90 días | Genera uno nuevo y vuelve a hacer push. |

---

## 14. Glosario

- **GCP:** Google Cloud Platform, la nube de Google.
- **Project ID:** identificador único global de tu proyecto en GCP.
- **Billing account:** cuenta de facturación; necesaria aunque uses free tier.
- **Free tier / Free trial:** créditos gratis (USD 300/90 días) + servicios siempre gratis con límites.
- **Cloud Shell:** terminal Linux gratuita en el navegador con herramientas preinstaladas.
- **gcloud:** CLI para administrar GCP.
- **API:** interfaz que se debe "habilitar" para usar cada servicio.
- **Data Lake:** almacén de archivos crudos (Cloud Storage).
- **Data Warehouse:** base analítica SQL para grandes volúmenes (BigQuery).
- **Repositorio (repo):** carpeta versionada de tu código en GitHub.
- **PAT (Personal Access Token):** token que reemplaza la contraseña para autenticarte en GitHub.
- **Región/Zona:** ubicación física de los servidores donde corren tus recursos.
- **`.gitignore`:** archivo que le dice a Git qué NO subir (ej. credenciales, temporales).

---

> **➡️ Siguiente:** [Manual 01 — Ingesta de datos y Data Lake](./01_ingesta_datos_y_data_lake.md)
