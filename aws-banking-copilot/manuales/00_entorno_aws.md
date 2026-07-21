# Manual 00 — Configuración del entorno en AWS

> **Objetivo:** Dejar listo TODO el entorno de trabajo en **Amazon Web Services (AWS)** para construir el **Banking Policy Copilot** (asistente RAG de fraude/banca con Amazon Bedrock), sin gastar de más y usando los **métodos actuales** (no los de tutoriales viejos). Al terminar tendrás: una cuenta de AWS **asegurada** (root protegida con MFA), **alertas de presupuesto** activas, una **identidad de trabajo moderna** (IAM Identity Center, credenciales temporales), tu terminal en la nube (**CloudShell**) y en tu PC (**AWS CLI + boto3**), **acceso a los modelos de Bedrock** habilitado y probado, y la estructura del proyecto en Git.
>
> **Tiempo estimado:** 2–3 horas.
> **Lo único que necesitas en tu PC:** un navegador (Chrome recomendado), un correo, y una tarjeta (solo para verificar identidad; con el **plan Free no te cobran**).

> ⚠️ **Este manual usa métodos vigentes a julio de 2026** (ver [§15 Fuentes](#15-fuentes)). AWS cambia sus consolas seguido: donde un botón pueda haberse movido, te doy también la **ruta por menú** y el **comando CLI** equivalente, que son más estables. Si algo no calza exactamente, la lógica del paso sigue siendo la misma.

---

## 🖱️ / ⌨️ Cómo leer este manual (UI + CLI)

Igual que en el proyecto GCP, este manual va en **doble camino**:

- 🖱️ **Por la Consola (UI):** clic por clic en la consola web de AWS (`console.aws.amazon.com`). Es lo más intuitivo: *ves* lo que haces.
- ⌨️ **Equivalente en CLI:** el mismo resultado con un comando, en **CloudShell** (terminal dentro del navegador) o en tu PC. Es lo que se *espera* que domines en una entrevista de AWS.

👉 **Puedes completar casi todo el manual solo con la UI.** El CLI está al lado como referencia y "músculo".

💡 **Consejo:** haz cada paso primero por la UI para entenderlo; luego, si quieres, repítelo por CLI en una segunda pasada.

🔁 **Marcador multi-cloud:** como este proyecto es AWS pero tú ya vienes de GCP, con el ícono 🔁 te doy el **equivalente en GCP** de cada concepto. Eso es exactamente lo que te preguntarán ("¿y esto en GCP cómo sería?") y lo que sostiene tu pitch multi-cloud.

---

## 📋 Tabla de contenido

1. [Conceptos previos (lee esto primero)](#1-conceptos-previos)
2. [Crear y asegurar la cuenta de AWS](#2-cuenta-aws)
3. [Créditos gratuitos y cómo NO gastar de más](#3-creditos)
4. [Elegir tu región de trabajo](#4-region)
5. [Presupuesto y alertas (AWS Budgets)](#5-budgets)
6. [Identidad de trabajo: IAM Identity Center (método moderno)](#6-identity-center)
7. [Tu terminal: CloudShell (nube) y AWS CLI (PC)](#7-terminal)
8. [boto3 (el SDK de Python para AWS)](#8-boto3)
9. [Habilitar acceso a los modelos de Bedrock](#9-model-access)
10. [Probar Bedrock (Playground + CLI + Python)](#10-probar-bedrock)
11. [Estructura del proyecto y primer commit](#11-estructura)
12. [✅ Checklist final del Manual 00](#12-checklist)
13. [🛟 Solución de problemas](#13-troubleshooting)
14. [📖 Glosario](#14-glosario)
15. [🔗 Fuentes (verificadas jul-2026)](#15-fuentes)

---

## 1. Conceptos previos

Antes de tocar nada, entiende **qué es cada cosa**. Esto te ahorra confusión todo el proyecto.

📖 **AWS (Amazon Web Services):** la nube más usada del mundo y la que aparece primero en las vacantes que persigues. Es el equivalente a GCP, con otros nombres.

📖 **Cuenta AWS:** el contenedor de todo. A diferencia de GCP (donde el contenedor es el *proyecto*), en AWS el contenedor principal es la **cuenta** (identificada por un número de 12 dígitos). Dentro separas cosas por **región**, **servicios** y **etiquetas**, no por "proyectos".
> 🔁 **GCP:** una *cuenta AWS* ≈ un *proyecto GCP* (a grandes rasgos, como frontera de facturación y recursos).

📖 **Usuario root:** el correo con el que creas la cuenta. Tiene **poder absoluto** (puede cerrar la cuenta, cambiar facturación). **Regla de oro: NO se usa para trabajar a diario.** Lo aseguras con MFA y lo guardas bajo llave. Para el día a día usas una identidad limitada (§6).

📖 **Región (Region):** el centro de datos físico donde viven tus recursos (ej. `us-east-1` = Virginia del Norte). Importa porque **Bedrock y ciertos modelos (Claude) no están en todas las regiones**, y porque los precios varían.
> 🔁 **GCP:** igual concepto (`us-central1`, etc.).

📖 **IAM (Identity and Access Management):** el sistema de permisos de AWS. Define **quién** puede hacer **qué** sobre **cuáles** recursos.
> 🔁 **GCP:** también se llama IAM. Mismo concepto (roles, políticas, principio de mínimo privilegio).

📖 **IAM Identity Center:** la forma **moderna y recomendada** de darte a ti mismo (y a un equipo) acceso a AWS con **credenciales temporales** que se renuevan solas. Reemplaza la vieja práctica de "crear un usuario IAM y generar access keys permanentes" (que hoy AWS **desaconseja** por seguridad).
> ⚠️ Muchos tutoriales viejos te dicen "crea un IAM user y genera access keys". Eso **funciona pero es legacy**. Aquí aprendes el camino correcto; el legacy queda como nota.

📖 **Amazon Bedrock:** el servicio gestionado de AWS para usar **modelos de fundación (LLMs)** — Claude (Anthropic), Titan (Amazon), Llama, etc. — vía API, sin administrar servidores. Es el **corazón de este proyecto**.
> 🔁 **GCP:** **Vertex AI** (Model Garden / Gemini). Bedrock ≈ Vertex AI.

📖 **Amazon S3 (Simple Storage Service):** almacenamiento de archivos (objetos). Aquí guardarás los documentos de políticas/fraude que alimentan el RAG. Es tu **Data Lake**.
> 🔁 **GCP:** **Cloud Storage**. S3 ≈ Cloud Storage.

📖 **CloudShell:** una terminal Linux **dentro del navegador**, gratis, con el AWS CLI ya instalado y **autenticada con tu sesión** (no manejas llaves). Ideal para empezar sin instalar nada.
> 🔁 **GCP:** **Cloud Shell**. Mismo concepto.

📖 **AWS CLI:** la herramienta de línea de comandos para controlar AWS. Viene en CloudShell; en tu PC la instalas.
> 🔁 **GCP:** `gcloud`.

📖 **boto3:** el **SDK de Python** para AWS. Con él tu código Python habla con Bedrock, S3, etc. Lo usarás muchísimo.
> 🔁 **GCP:** las librerías `google-cloud-*`.

📖 **AWS Budgets:** el servicio para poner **alertas de gasto**. Es tu cinturón de seguridad contra sorpresas.
> 🔁 **GCP:** *Budgets & alerts*. Mismo concepto.

### 🗺️ Mini-mapa AWS ↔ GCP (memorízalo, te lo preguntan)

| Necesidad | AWS | GCP |
|---|---|---|
| Contenedor / facturación | Cuenta | Proyecto |
| Almacenamiento de archivos (Data Lake) | **S3** | Cloud Storage |
| LLMs gestionados | **Bedrock** | Vertex AI / Model Garden |
| Vector store gestionado | **OpenSearch Serverless** | Vertex AI Vector Search |
| RAG gestionado | **Bedrock Knowledge Bases** | Vertex AI Search / RAG Engine |
| Guardrails de IA | **Bedrock Guardrails** | Model Armor |
| Funciones serverless | **Lambda** | Cloud Functions / Cloud Run |
| Puerta de API | **API Gateway** | API Gateway / Cloud Endpoints |
| Logs y métricas | **CloudWatch** | Cloud Logging / Monitoring |
| Terminal en navegador | **CloudShell** | Cloud Shell |
| CLI | **aws** | gcloud |

---

## 2. Cuenta AWS

> ⏭️ **¿Ya creaste una cuenta AWS?** (Por ejemplo en el Manual 00 del proyecto GCP, parte B). Si es así, **sáltate la creación** y ve directo a **§2.2 (asegurar la cuenta)**. Solo verifica en §3 si tu cuenta es "nueva" o "legacy" según su fecha.

### Paso 2.1 — Crear la cuenta (100% por UI, no hay otra forma)

1. Ve a **https://aws.amazon.com/** y clic en **"Crear una cuenta de AWS"** (Create an AWS Account), arriba a la derecha.
2. **Correo raíz + nombre de cuenta:** usa un correo que controles (puede ser `danielcaro317@gmail.com`). Nombre de cuenta: `banking-copilot` (puedes cambiarlo luego).
3. Verifica el correo con el código que te envían.
4. **Contraseña del root:** ponla larga y única. Guárdala en tu gestor de contraseñas.
5. **Datos de contacto:** tipo **Personal**, tu nombre y dirección.
6. **Tarjeta:** requerida solo para verificar identidad. Verás un cargo temporal de ~USD 1 que se reversa.
7. **Verificación por teléfono** (SMS o llamada).
8. **Elige el plan de soporte:** **Basic support — Free**. (El gratis basta para todo esto.)
9. **Elige el plan de cuenta (¡importante!):** verás **Free** vs **Paid** (ver §3). Para aprender sin riesgo, empieza en **Free**.

### ✅ Checkpoint 2.1
Llegas a la consola de AWS (`https://console.aws.amazon.com/`) e inicias sesión como **Root user** con tu correo. Si ves el panel principal, vas bien.

### Paso 2.2 — Asegurar la cuenta root (NO opcional)

El root es demasiado poderoso para dejarlo sin candado. Actívale **MFA** (segundo factor) **ahora**.

🖱️ **Por la Consola (UI):**
1. Inicia sesión como **root**.
2. Arriba a la derecha, clic en tu nombre de cuenta → **Security credentials** (Credenciales de seguridad).
3. En **Multi-factor authentication (MFA)**, clic en **Assign MFA device**.
4. Elige **Authenticator app** (Google Authenticator, Authy, Microsoft Authenticator, etc.).
5. Escanea el QR con la app del teléfono e ingresa **dos códigos consecutivos**. Confirma.

### ✅ Checkpoint 2.2
En **Security credentials** debe aparecer tu dispositivo MFA como **activo**. A partir de aquí, para entrar como root te pedirá el código del teléfono.

💡 **Regla de oro:** después de este manual, **no vuelvas a usar el root** salvo para tareas de facturación. Todo el trabajo será con la identidad de §6.

🛟 *Si no puedes escanear el QR:* usa la opción "mostrar código secreto" y escríbelo a mano en la app.

---

## 3. Créditos gratuitos y cómo NO gastar de más

AWS renovó su capa gratuita en **julio de 2025**. Lo que aplica depende de **cuándo creaste tu cuenta**:

- **Cuenta creada el 15-jul-2025 o después (nueva):**
  - Recibes **USD 100 en créditos al registrarte** + hasta **USD 100 adicionales** por completar actividades (usar EC2, **Bedrock**, **AWS Budgets**, etc.) → **hasta USD 200**.
  - Válidos por **12 meses**; en el **plan Free**, la cuenta se pausa/cierra a los **6 meses** o cuando se agoten los créditos (lo que ocurra primero).
  - **Plan Free** = no te pueden cobrar (se pausa antes). **Plan Paid** = pagas lo que exceda; para eso son las alertas de §5.
- **Cuenta creada antes del 15-jul-2025 (legacy):** sigues en el esquema viejo (12-month free trial de ciertos servicios + "always free"), **sin** los USD 200.

⚠️ **Lo más importante que debes grabarte:**
- **Bedrock NO es gratis:** pagas **por token** (entrada/salida). Son centavos por consulta, pero suma. Los créditos lo cubren al inicio.
- **OpenSearch Serverless** (lo usarás en el manual de retrieval) tiene un **costo mínimo por hora aunque no lo uses** (se factura por *OCU*). Es la causa #1 de "sustos" en la factura. **Lo montaremos y lo APAGAREMOS/BORRAREMOS** en cada sesión, y te lo recuerdo en ese manual.
- Por eso: **§5 (Budgets) no es opcional.**

💡 **Tip que además te da créditos:** crear un presupuesto en AWS Budgets (§5) es una de las "actividades" que otorgan crédito en cuentas nuevas. Matas dos pájaros.

---

## 4. Región

Elige **una** región y trabaja siempre ahí (mezclar regiones causa errores de "recurso no encontrado").

**Recomendación: `us-east-1` (N. Virginia).** Es donde Bedrock tiene la **mayor disponibilidad de modelos** (incluido Claude) y donde casi todos los ejemplos funcionan sin ajustes. Alternativa: `us-west-2` (Oregón).

🖱️ **Por la Consola (UI):** arriba a la derecha, junto a tu nombre, hay un **selector de región**. Elige **US East (N. Virginia) us-east-1**.

⌨️ **En CLI** (lo configurarás en §7):
```bash
aws configure set region us-east-1
```

### ✅ Checkpoint 4
Arriba a la derecha la consola dice **N. Virginia**. Déjalo así todo el proyecto.

💡 **Sobre "inference profiles":** algunos modelos nuevos de Bedrock se invocan por un **perfil de inferencia cross-región** (un ID que empieza por `us.` en vez de `anthropic.`). No te preocupes ahora; en §9–10 te muestro cómo obtener el ID exacto desde la consola, que es a prueba de cambios.

---

## 5. Budgets

⚠️ **Paso obligatorio.** Te protege de cobros inesperados y (en cuentas nuevas) te da crédito.

🖱️ **Por la Consola (UI):**
1. En la barra de búsqueda de arriba escribe **"Budgets"** y entra a **AWS Budgets** (ruta de menú: tu nombre → **Billing and Cost Management** → **Budgets**).
2. Clic en **Create budget**.
3. Elige plantilla **"Zero spend budget"** (te avisa apenas gastes más de USD 0 por encima del free tier) **o** **"Monthly cost budget"** con un umbral (ej. USD 10).
   - 💡 Para aprender, el **Zero spend budget** es el más seguro: te alerta ante cualquier gasto real.
4. Pon tu **correo** como destinatario de la alerta.
5. **Create budget.**

⌨️ **Equivalente en CLI** (opcional; requiere un JSON de definición):
```bash
# La forma más simple y sin errores es por la UI.
# Por CLI usarías: aws budgets create-budget --account-id <TU_ID> --budget file://budget.json ...
# (lo dejamos por UI para no complicar; el concepto es el mismo)
```

### ✅ Checkpoint 5
En **Budgets** ves tu presupuesto creado y, en unos minutos, te llega (o llegará) un correo de confirmación de la alerta. 

🛟 *Si no ves "Billing":* solo el **root** o una identidad con permiso de facturación lo ve. Entra como root para este paso.

---

## 6. Identity Center

Aquí creas tu **identidad de trabajo diaria** (la que usarás en vez del root). Usamos **IAM Identity Center**, el método **recomendado por AWS** (credenciales **temporales**, se renuevan solas, más seguro que las access keys permanentes).

> 💡 **¿Por qué no "un usuario IAM con access keys"?** Porque esas llaves son **permanentes**: si se filtran (en un commit, un log), alguien tiene acceso indefinido. Identity Center entrega llaves **que caducan solas**. En una entrevista, decir *"uso IAM Identity Center con credenciales temporales, no access keys de larga duración"* te posiciona como alguien que sabe seguridad.

### Paso 6.1 — Habilitar IAM Identity Center

🖱️ **Por la Consola (UI):**
1. Busca **"IAM Identity Center"** en la barra de arriba y entra.
2. Clic en **Enable**. (AWS creará automáticamente una *organización* mínima; es normal y gratis.)
3. Verás una **URL del portal de acceso** (algo como `https://d-xxxxxxxxxx.awsapps.com/start`). **Guárdala**: es por donde iniciarás sesión de ahora en adelante.

### Paso 6.2 — Crear un "permission set" (conjunto de permisos)

Un *permission set* define qué puede hacer tu usuario. Para aprender, uno de administrador está bien (luego, en el manual de seguridad, aplicaremos **mínimo privilegio** de verdad).

1. En Identity Center → **Permission sets** → **Create permission set**.
2. Elige **Predefined permission set** → **AdministratorAccess**. (Nota mental: en producción esto sería demasiado; lo afinaremos.)
3. Nómbralo y crea.

### Paso 6.3 — Crear tu usuario y asignarle acceso

1. Identity Center → **Users** → **Add user**.
2. Username, tu correo, nombre. Crea.
3. Revisa tu correo y **acepta la invitación** → define tu contraseña y **activa MFA** (otra vez el authenticator; sí, este usuario también lleva MFA).
4. Vuelve a Identity Center → **AWS accounts** → selecciona tu cuenta → **Assign users or groups** → elige tu usuario → asígnale el **permission set AdministratorAccess**.

### ✅ Checkpoint 6
Abre la **URL del portal de acceso** en una ventana nueva, inicia sesión con tu usuario (no el root), y entra a la consola por ahí. **Este es tu nuevo login para trabajar.**

🛟 *Si el portal no carga:* espera 1–2 min tras habilitar Identity Center; la propagación tarda.

🔁 **GCP:** el equivalente conceptual es tener cuentas de usuario con roles IAM en vez de usar la cuenta dueña del proyecto para todo.

---

## 7. Terminal

Tienes **dos formas** de correr comandos. Empieza por CloudShell (cero configuración).

### 7.1 — CloudShell (en el navegador, recomendado para empezar)

🖱️ **Por la Consola (UI):** estando logueado (por el portal de §6), busca el ícono de **CloudShell** (`>_`) arriba a la derecha, o busca "CloudShell". Ábrelo.

- Ya trae **AWS CLI**, **Python** y **boto3**. Está **autenticado con tu sesión** (no manejas llaves). 
- Pruébalo:
```bash
aws sts get-caller-identity
```
Debe mostrar tu **Account ID** y tu identidad (el ARN de tu usuario de Identity Center). Si lo ves, CloudShell funciona.

```bash
aws configure set region us-east-1     # fija tu región por defecto
aws bedrock list-foundation-models --region us-east-1 --query "modelSummaries[?contains(modelId, 'claude')].modelId" --output table
```
Esto **lista los modelos Claude disponibles** en tu región. Si sale una tabla con IDs, ¡Bedrock ya te responde a nivel de control!

### ✅ Checkpoint 7.1
`aws sts get-caller-identity` devuelve tu cuenta; el listado de modelos Claude muestra IDs.

### 7.2 — AWS CLI en tu PC (con credenciales temporales de Identity Center)

Para trabajar desde tu máquina (VS Code, scripts, IaC) sin manejar llaves permanentes:

1. **Instala el AWS CLI v2** (macOS):
```bash
# macOS (con el instalador oficial)
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
aws --version   # debe decir aws-cli/2.x
```
2. **Configura el acceso por SSO (Identity Center):**
```bash
aws configure sso
```
Te preguntará:
- **SSO start URL:** la URL del portal de §6 (`https://d-xxxx.awsapps.com/start`).
- **SSO region:** la región donde habilitaste Identity Center (normalmente `us-east-1`).
- Se abrirá el navegador para que **autorices**. Luego eliges tu **cuenta** y **permission set**.
- **CLI default region:** `us-east-1`. **Output:** `json`. **Profile name:** `copilot` (o el que quieras).
3. **Inicia sesión y prueba:**
```bash
aws sso login --profile copilot
aws sts get-caller-identity --profile copilot
```

💡 Con esto, tus comandos y tu código usan **credenciales temporales** que se renuevan con `aws sso login`. Cuando caduquen, solo repites ese comando. **Nunca escribes una access key en un archivo.**

### ✅ Checkpoint 7.2
`aws sts get-caller-identity --profile copilot` desde tu PC devuelve tu identidad.

🛟 *Windows/Linux:* el instalador cambia (MSI en Windows, `curl`+`unzip` en Linux); busca "Install AWS CLI v2 <tu SO>" en docs.aws.amazon.com.

---

## 8. boto3

`boto3` es como tu código Python hablará con AWS. Prepáralo en tu PC (en CloudShell ya viene).

1. Crea un entorno virtual y instala:
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install boto3
```
2. boto3 **usa automáticamente** el perfil que configuraste (`AWS_PROFILE=copilot`) o el default. Prueba:
```bash
export AWS_PROFILE=copilot          # usa tu perfil SSO
python3 -c "import boto3; print(boto3.client('sts').get_caller_identity()['Account'])"
```
Debe imprimir tu **Account ID**.

### ✅ Checkpoint 8
El comando anterior imprime tu número de cuenta (12 dígitos). Ya tienes Python ↔ AWS conectados.

🛟 *Error `Unable to locate credentials`:* corre `aws sso login --profile copilot` (la sesión SSO caducó) y verifica `echo $AWS_PROFILE`.

---

## 9. Model access

Bedrock exige **habilitar el acceso** a los modelos que usarás (Claude para generar, Titan para embeddings). Desde 2025 hay **acceso simplificado**: muchos modelos vienen **habilitados por defecto**; otros los activas en un clic.

🖱️ **Por la Consola (UI):**
1. Entra a **Amazon Bedrock** (búscalo arriba). Confirma región **N. Virginia**.
2. En el panel izquierdo, bajo **Bedrock configurations**, clic en **Model access**.
3. Clic en **Modify model access** (o **Enable specific models**).
4. Marca al menos:
   - **Anthropic → Claude** (el modelo de generación; marca el/los Claude disponibles).
   - **Amazon → Titan Text Embeddings** (para los embeddings del RAG).
5. Acepta el **EULA** si lo pide y confirma. El **Access status** pasa a **Access granted**.

⌨️ **Verificación por CLI:**
```bash
# Modelos con acceso concedido en tu región:
aws bedrock list-foundation-models --region us-east-1 \
  --query "modelSummaries[].{id:modelId, provider:providerName}" --output table
```

### ✅ Checkpoint 9
En **Model access** ves **Access granted** frente a un modelo Claude y a Titan Embeddings.

🛟 *No aparece Claude para habilitar:* cambia a `us-east-1` o `us-west-2` (no todas las regiones tienen Claude). Si dice "Available to request", solicítalo; suele aprobarse al instante.

---

## 10. Probar Bedrock

Vamos a hacer que un modelo **te responda** de tres formas: consola, CLI y Python. Esto confirma que TODO el entorno (identidad + región + acceso a modelo) quedó bien.

### 10.1 — Por la Consola (Playground)

🖱️ Bedrock → panel izquierdo **Playgrounds** → **Chat / Text**. Elige un modelo **Claude**. Escribe *"Hola, responde en una frase para probar que funcionas."* y **Run**. Debe contestar.

💡 **Truco de oro:** en el Playground suele haber un botón **"View API request"** que te muestra el **JSON exacto** y el **modelId** para llamar ese modelo por API. **Cópialo**: ese `modelId` es el que usarás en CLI/Python (y evita adivinar IDs que cambian).

### 10.2 — Por CLI (Converse API — la moderna y unificada)

```bash
# Sustituye <MODEL_ID> por el que copiaste del Playground
# (ej. un ID que empieza por 'anthropic.claude-...' o por 'us.anthropic.claude-...')
aws bedrock-runtime converse \
  --region us-east-1 \
  --model-id "<MODEL_ID>" \
  --messages '[{"role":"user","content":[{"text":"Hola, responde en una sola frase."}]}]'
```
Debe devolver un JSON con la respuesta dentro de `output.message.content[0].text`.

### 10.3 — Por Python (boto3, la que usarás en el proyecto)

Crea `aws-banking-copilot/ingestion/smoke_test_bedrock.py`:
```python
import boto3

# Usa tu perfil SSO (export AWS_PROFILE=copilot) o el default
client = boto3.client("bedrock-runtime", region_name="us-east-1")

MODEL_ID = "<MODEL_ID>"  # el que copiaste del Playground

resp = client.converse(
    modelId=MODEL_ID,
    messages=[{"role": "user", "content": [{"text": "Hola, responde en una sola frase."}]}],
)
print(resp["output"]["message"]["content"][0]["text"])
```
Córrelo:
```bash
export AWS_PROFILE=copilot
python3 aws-banking-copilot/ingestion/smoke_test_bedrock.py
```

### ✅ Checkpoint 10
Las tres vías (Playground, CLI, Python) te devuelven una respuesta del modelo. **Si Python responde, tu entorno de desarrollo está 100% listo.**

🛟 *`AccessDeniedException`:* falta habilitar el modelo (§9) o tu identidad no tiene permiso de Bedrock. *`ValidationException` sobre el modelId:* usa el ID exacto del Playground; algunos modelos exigen el **inference profile** (`us.anthropic...`) en vez del ID base.

---

## 11. Estructura

La estructura de carpetas ya está creada en el repo (la generamos al organizar el proyecto). Verifícala:

```bash
cd aws-banking-copilot
ls -1
# api  eval  guardrails  infra  ingestion  langchain  manuales  retrieval
```

- `ingestion/` — carga de documentos a S3, parsing, chunking, metadata
- `retrieval/` — Knowledge Bases, OpenSearch, Retrieve/RetrieveAndGenerate
- `guardrails/` — Bedrock Guardrails y sus pruebas
- `eval/` — dataset dorado y evaluación (retrieval + generación)
- `api/` — API de consulta (FastAPI)
- `langchain/` — variante LangChain-sobre-Bedrock
- `infra/` — IaC (CDK o Terraform)

### Primer commit

> ⚠️ **Nunca subas credenciales.** Con Identity Center/SSO no tienes archivos de llaves, pero por si acaso, verifica que `.env`, `*.pem`, `.aws/` estén en `.gitignore`.

```bash
cd /Users/macbookpro/Documents/MAIA/fraudshield
git add aws-banking-copilot/ README.md
git commit -m "AWS Manual 00: entorno Bedrock listo (identidad, región, budgets, model access)"
```
> 💡 El commit lo haces **tú cuando quieras** (yo no comiteo sin que me lo pidas). Lo que no está en GitHub, no existe para el reclutador.

---

## 12. Checklist

- [ ] Cuenta AWS creada y **root protegido con MFA**.
- [ ] Sé si mi cuenta es **nueva** (créditos $200) o **legacy**.
- [ ] **Budget/alerta** de gasto creado.
- [ ] Región fijada en **us-east-1**.
- [ ] **IAM Identity Center** habilitado; **uso mi usuario (no root)** para trabajar.
- [ ] **CloudShell** funciona (`aws sts get-caller-identity`).
- [ ] **AWS CLI + SSO** configurado en mi PC (`aws sso login --profile copilot`).
- [ ] **boto3** conectado (imprime mi Account ID).
- [ ] **Acceso a modelos** de Bedrock concedido (Claude + Titan Embeddings).
- [ ] Bedrock **responde** por Playground, CLI y Python.
- [ ] Estructura del proyecto verificada y (opcional) primer commit.

Si marcaste todo: **tu entorno AWS está listo.** El siguiente manual construye el RAG desde cero en Python (sin framework) para entender cada pieza antes de tocar Bedrock Knowledge Bases.

---

## 13. Troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| No veo "Billing"/"Budgets" | No eres root ni tienes permiso de facturación | Entra como **root** para facturación |
| `AccessDeniedException` en Bedrock | Modelo no habilitado o falta permiso | §9 (model access) y usa el permission set Admin |
| `Could not connect to the endpoint URL` | Región equivocada | `--region us-east-1` en todo |
| `Unable to locate credentials` | Sesión SSO caducó | `aws sso login --profile copilot` |
| `ValidationException` con el modelId | ID incorrecto o requiere inference profile | Copia el `modelId` del botón "View API request" del Playground |
| Claude no aparece en Model access | Región sin Claude | Cambia a `us-east-1` / `us-west-2` |
| Miedo a la factura | OpenSearch/servicios encendidos | Revisa **Budgets** y **borra** recursos al terminar cada sesión (te aviso en cada manual) |

---

## 14. Glosario

- **Cuenta / Account ID:** contenedor raíz de AWS (número de 12 dígitos).
- **Root user:** dueño absoluto de la cuenta; solo para facturación, con MFA.
- **Región:** ubicación física de los recursos (`us-east-1`).
- **IAM:** permisos (quién puede qué).
- **IAM Identity Center:** identidades con **credenciales temporales** (método moderno).
- **Permission set:** conjunto de permisos asignable a un usuario en Identity Center.
- **MFA:** segundo factor de autenticación (app del teléfono).
- **Bedrock:** LLMs gestionados por API.
- **Converse API:** la API unificada de Bedrock para chatear con cualquier modelo.
- **Foundation model / modelId:** el modelo (Claude, Titan…) y su identificador.
- **Inference profile:** ID cross-región para invocar ciertos modelos (`us.anthropic…`).
- **S3:** almacenamiento de objetos (Data Lake).
- **CloudShell:** terminal en el navegador, autenticada con tu sesión.
- **AWS CLI / boto3:** herramientas de línea de comandos / SDK Python.
- **Budgets:** alertas de gasto.

---

## 15. Fuentes

Verificadas el **21 de julio de 2026** (por si algo cambia, aquí tienes la fuente oficial):

- Habilitar acceso a modelos en Bedrock — [docs.aws.amazon.com/bedrock/latest/userguide/model-access.html](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access.html) y [model-access-modify.html](https://docs.aws.amazon.com/bedrock/latest/userguide/model-access-modify.html)
- Acceso simplificado a modelos — [aws.amazon.com/blogs/security/simplified-amazon-bedrock-model-access/](https://aws.amazon.com/blogs/security/simplified-amazon-bedrock-model-access/)
- IAM Identity Center como método recomendado (credenciales temporales vs access keys) — [docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html) y [cli-configure-sso.html](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)
- Nueva capa gratuita ($200 en créditos, cuentas desde 15-jul-2025) — [aws.amazon.com/blogs/aws/aws-free-tier-update...](https://aws.amazon.com/blogs/aws/aws-free-tier-update-new-customers-can-get-started-and-explore-aws-with-up-to-200-in-credits/) y [aws.amazon.com/free/](https://aws.amazon.com/free/)
- Empezar en la consola de Bedrock — [docs.aws.amazon.com/bedrock/latest/userguide/getting-started-console.html](https://docs.aws.amazon.com/bedrock/latest/userguide/getting-started-console.html)

---

> **➡️ Siguiente manual:** `01_rag_desde_cero_python.md` — construir un RAG mínimo en Python puro (documentos → chunking → embeddings → vector store local → retrieval → prompt → respuesta con citas) para **entender cada pieza** antes de delegar en Bedrock Knowledge Bases. Tal como recomienda tu diagnóstico de aprendizaje.
