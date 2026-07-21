# Manual 05B — Agentes y workflows con LangGraph

> **Objetivo:** Construir un **Agente Investigador de Fraude** que ejecuta un **workflow multi-paso** con **LangGraph**: dada una transacción, la **recupera**, la **puntúa** con tu modelo de ML (Manual 04), busca **quejas similares** con tu RAG (Manual 05) y **redacta un borrador de reporte de actividad sospechosa (SAR)** — con un punto de **revisión humana**. Esto cubre el requisito estrella de Proxify: *"AI agents and multi-step workflows"*.
>
> **Tiempo estimado:** 5–7 horas.
> **Prerrequisito:** Manual 04 (modelo `fraud_model.joblib`) + Manual 05 (RAG + ChromaDB) funcionando localmente.
> **Cubre del cargo:** **Proxify**: AI agents and workflows, LangGraph (nice-to-have estrella), orquestación de herramientas de IA · refuerza RAG y ML.
> **Dónde:** **tu PC local** (reusa Ollama, el modelo y la base vectorial). 🔁 callout de producción.

---

## 🖱️ / ⌨️ Cómo leer este manual (agente = código, con visual donde se puede)

Igual que el RAG: **un agente se construye con código.** Es la habilidad estrella que Proxify busca, así que la practicamos de verdad. Pero la hacemos amable:

- 🖱️ **Corre el agente en un notebook** (Jupyter en VS Code) para **ver cada paso** del grafo imprimirse en orden (fetch → score → decisión → …). Es la mejor forma de *entender* el flujo.
- 🖱️ **LangGraph sí tiene visual:** puedes **dibujar el grafo** (`draw_mermaid()` / `draw_ascii()`) y verlo como diagrama. Y existe **LangGraph Studio**, una app visual para *ejecutar y depurar* agentes viendo el grafo animarse paso a paso (callout en §6).
- 🖱️ **Datos por UI:** exportar el modelo y la muestra se hace desde la consola de BigQuery / Cloud Storage.
- ⌨️ **Terminal:** también puedes correr `python fraud_agent.py`.

👉 **Para semi-junior:** trabaja en notebook, ejecuta celda por celda, y dibuja el grafo para tu portafolio. Ver el flujo animarse ayuda muchísimo a entender qué es un "agente".

---

## 📋 Tabla de contenido

1. [Conceptos previos: ¿qué es un agente?](#1-conceptos)
2. [LangGraph: grafos de estado](#2-langgraph)
3. [El diseño de nuestro agente](#3-diseno)
4. [Prerrequisitos: traer modelo y datos a local](#4-prerrequisitos)
5. [Construir el agente paso a paso](#5-construir)
6. [Ejecutar el agente](#6-ejecutar)
7. [Human-in-the-loop (revisión humana)](#7-human)
8. [Variante: agente autónomo (ReAct + tools)](#8-react)
9. [Observabilidad y producción](#9-produccion)
10. [Commit a GitHub](#10-commit)
11. [✅ Checklist final](#11-checklist)
12. [🛟 Solución de problemas](#12-troubleshooting)
13. [📖 Glosario](#13-glosario)

---

## 1. Conceptos

📖 **Agente de IA:** un sistema donde un **LLM decide qué hacer** y usa **herramientas (tools)** para lograr un objetivo, en **varios pasos**, en lugar de responder de una sola vez. Mientras un RAG responde una pregunta, un **agente ejecuta un proceso** (investigar, decidir, actuar).

📖 **Tool (herramienta):** una función que el agente puede invocar (consultar una BD, puntuar con un modelo, buscar en el RAG, enviar un correo). El LLM elige **cuál** usar y **con qué argumentos**.

📖 **Patrón ReAct (Reason + Act):** el agente **razona** ("necesito el score"), **actúa** (llama la tool de scoring), **observa** el resultado, y repite hasta terminar.

📖 **Workflow vs agente autónomo:**
- **Workflow (grafo definido):** tú defines los pasos y el orden (con ramas). Predecible y confiable → ideal en banca. **Es lo que construiremos.**
- **Agente autónomo (ReAct):** el LLM decide los pasos en tiempo real. Más flexible, menos predecible (§8).

💡 **Por qué un agente aquí:** investigar un fraude **no es una sola pregunta**: es recuperar la transacción → puntuarla → buscar contexto → decidir → redactar. Eso es un **workflow multi-paso** = trabajo de agente.

---

## 2. Langgraph

📖 **LangGraph:** librería (de los creadores de LangChain) para construir agentes/workflows como un **grafo de estado**:
- **State (estado):** un objeto compartido que va acumulando información a medida que avanza (la transacción, el score, las quejas, el SAR).
- **Nodes (nodos):** funciones que reciben el estado, hacen algo y devuelven una actualización del estado.
- **Edges (aristas):** conexiones que definen el orden. Pueden ser **condicionales** (ramas: si es sospechosa → investigar; si no → cerrar).
- **Cycles (ciclos):** a diferencia de un DAG de Airflow, un grafo de LangGraph **puede volver atrás** (reintentar, refinar) — útil para agentes.

💡 **Diferencia con Airflow (Manual 03):** Airflow orquesta **pipelines de datos** (batch, programados). LangGraph orquesta **razonamiento de IA** (por petición, con ramas y ciclos). Distintas herramientas, distinto propósito.

---

## 3. Diseno

Nuestro **Agente Investigador de Fraude** como grafo:

```
            ┌──────────┐
   START ──►│  fetch   │  recupera la transacción
            └────┬─────┘
                 ▼
            ┌──────────┐
            │  score   │  la puntúa con el modelo ML (Manual 04)
            └────┬─────┘
                 ▼
            ¿is_suspicious?  ◄── arista CONDICIONAL
            ╱            ╲
       sí  ╱              ╲  no
          ▼                ▼
   ┌─────────────┐    ┌─────────┐
   │ investigate │    │  close  │  cierra el caso
   │ (RAG: busca │    └────┬────┘
   │  quejas)    │         │
   └──────┬──────┘         │
          ▼                │
     ┌─────────┐           │
     │  draft  │  redacta el SAR
     │  (LLM)  │           │
     └────┬────┘           │
          ▼                ▼
              END
```

Cada nodo es una **tool/paso**; la arista condicional es la **decisión** del agente.

---

## 4. Prerrequisitos

El agente vive en `agents/` y necesita **2 archivos locales**: tu modelo y una muestra de transacciones. También la base vectorial del RAG (ya está en `rag/chroma_db`).

### 4.1 — Subir el modelo a GCS (si no lo hiciste en el Manual 04)

🖱️ **Por la UI:** Cloud Storage → bucket → `curated/models/` → **UPLOAD** el `fraud_model.joblib`.

⌨️ **Por CLI (Cloud Shell):**
```bash
export PROJECT_ID=$(gcloud config get-value project)
export BUCKET="gs://${PROJECT_ID}-datalake"
gcloud storage cp ~/fraudshield/ml/fraud_model.joblib "$BUCKET/curated/models/fraud_model.joblib"
```

### 4.2 — Exportar una muestra de transacciones

🖱️ **Por la UI (BigQuery):** editor → RUN:
```sql
CREATE OR REPLACE TABLE `fraud_dbt.tx_agent_sample` AS
SELECT * FROM `fraud_dbt.mart_fraud_features` WHERE is_fraud = 1 LIMIT 15
UNION ALL
SELECT * FROM `fraud_dbt.mart_fraud_features` WHERE is_fraud = 0 LIMIT 15;
```
Luego Explorer → `tx_agent_sample` → **⋮ → Export → Export to GCS** → `.../curated/tx_agent_sample.csv`.

⌨️ **Por CLI (Cloud Shell):**
```bash
bq query --use_legacy_sql=false --replace \
  --destination_table=fraud_dbt.tx_agent_sample \
  'SELECT * FROM `fraud_dbt.mart_fraud_features` WHERE is_fraud = 1 LIMIT 15
   UNION ALL
   SELECT * FROM `fraud_dbt.mart_fraud_features` WHERE is_fraud = 0 LIMIT 15'
bq extract --destination_format=CSV \
  fraud_dbt.tx_agent_sample "$BUCKET/curated/tx_agent_sample.csv"
```

### 4.3 — Descargar a tu PC 🖱️
Desde **Cloud Storage** en la consola → tu bucket → `curated/` → **DOWNLOAD** en `fraud_model.joblib` y `tx_agent_sample.csv`. (O Cloud Shell menú **⋮ → Download**.) Guárdalos en `fraudshield\agents\`.

### 4.4 — Instalar dependencias (en tu PC, reusa el venv del RAG)
```powershell
cd fraudshield\agents
..\rag\.venv\Scripts\Activate.ps1
pip install langgraph joblib xgboost scikit-learn pandas
```
💡 `xgboost` y `scikit-learn` son necesarios para **cargar** (`joblib.load`) tu modelo.

### ✅ Checkpoint 4
En `fraudshield\agents\` tienes `fraud_model.joblib` y `tx_agent_sample.csv`; las librerías instalaron OK.

---

## 5. Construir

`agents\fraud_agent.py` (o pégalo por bloques en un notebook):
```python
"""
Agente Investigador de Fraude (LangGraph):
  fetch -> score -> [condicional] -> investigate (RAG) -> draft (SAR)
                                  \-> close
"""
import json
from typing import TypedDict, Optional, List

import joblib
import pandas as pd
from langgraph.graph import StateGraph, START, END
from langchain_ollama import ChatOllama, OllamaEmbeddings
from langchain_chroma import Chroma

# ---------- Recursos (modelo, datos, RAG, LLM) ----------
BUNDLE = joblib.load("fraud_model.joblib")
CLF, THRESHOLD, FEATURES = BUNDLE["model"], BUNDLE["threshold"], BUNDLE["features"]
TX = pd.read_csv("tx_agent_sample.csv")

llm = ChatOllama(model="llama3.1:8b", temperature=0)

emb = OllamaEmbeddings(model="nomic-embed-text")
db = Chroma(
    persist_directory="../rag/chroma_db",
    embedding_function=emb,
    collection_name="complaints",
)
retriever = db.as_retriever(search_kwargs={"k": 3})


# ---------- Estado compartido ----------
class FraudState(TypedDict):
    tx_id: int
    transaction: Optional[dict]
    fraud_score: Optional[float]
    is_suspicious: Optional[bool]
    similar_complaints: Optional[List[str]]
    sar_draft: Optional[str]


# ---------- Nodos (pasos/herramientas) ----------
def fetch_transaction(state: FraudState):
    row = TX.iloc[state["tx_id"]].to_dict()
    print(f"🔎 Tx #{state['tx_id']}: tipo={row.get('transaction_type')} monto={row.get('amount')}")
    return {"transaction": row}


def score_transaction(state: FraudState):
    row = pd.DataFrame([state["transaction"]])
    row = row.drop(columns=[c for c in ["is_fraud"] if c in row.columns])
    X = pd.get_dummies(row)
    X = X.reindex(columns=FEATURES, fill_value=0)   # alinear con el modelo
    score = float(CLF.predict_proba(X)[0, 1])
    suspicious = score >= THRESHOLD
    print(f"📊 Score={score:.3f} (umbral {THRESHOLD:.3f}) -> {'SOSPECHOSA' if suspicious else 'OK'}")
    return {"fraud_score": score, "is_suspicious": suspicious}


def route_decision(state: FraudState):
    return "investigate" if state["is_suspicious"] else "close"


def investigate(state: FraudState):
    tx = state["transaction"]
    query = (f"transacción tipo {tx.get('transaction_type')} sospechosa de fraude "
             f"que vacía la cuenta del cliente")
    docs = retriever.invoke(query)
    complaints = [d.page_content[:300] for d in docs]
    print(f"📚 {len(complaints)} quejas similares recuperadas (RAG).")
    return {"similar_complaints": complaints}


def draft_sar(state: FraudState):
    quejas = "\n".join(f"- {c}" for c in state["similar_complaints"])
    prompt = f"""Eres un analista antifraude de un banco. Redacta un BORRADOR de
Reporte de Actividad Sospechosa (SAR), conciso y profesional.

Transacción: {json.dumps(state['transaction'], ensure_ascii=False)}
Score de fraude del modelo: {state['fraud_score']:.3f}
Quejas similares de clientes (contexto):
{quejas}

Estructura el SAR con: (1) Resumen, (2) Señales de alerta, (3) Recomendación."""
    sar = llm.invoke(prompt).content
    print("📝 SAR redactado.")
    return {"sar_draft": sar}


def close_case(state: FraudState):
    print("✅ No sospechosa. Caso cerrado.")
    return {"sar_draft": "N/A — transacción evaluada como legítima."}


# ---------- Construir el grafo ----------
def build_agent():
    g = StateGraph(FraudState)
    g.add_node("fetch", fetch_transaction)
    g.add_node("score", score_transaction)
    g.add_node("investigate", investigate)
    g.add_node("draft", draft_sar)
    g.add_node("close", close_case)

    g.add_edge(START, "fetch")
    g.add_edge("fetch", "score")
    g.add_conditional_edges("score", route_decision,
                            {"investigate": "investigate", "close": "close"})
    g.add_edge("investigate", "draft")
    g.add_edge("draft", END)
    g.add_edge("close", END)
    return g.compile()


if __name__ == "__main__":
    agent = build_agent()

    # Elegir una transacción fraudulenta y una legítima del sample
    fraud_ids = TX.index[TX["is_fraud"] == 1].tolist()
    legit_ids = TX.index[TX["is_fraud"] == 0].tolist()

    for tx_id in [fraud_ids[0], legit_ids[0]]:
        print("\n" + "=" * 70)
        result = agent.invoke({"tx_id": int(tx_id)})
        print("\n----- SAR -----")
        print(result["sar_draft"])
```

### ✅ Checkpoint 5
El archivo `agents/fraud_agent.py` está creado y se entiende: 5 nodos + 1 arista condicional.

---

## 6. Ejecutar

```powershell
python fraud_agent.py
```
(o ejecuta la celda del notebook). Verás el agente recorrer el grafo para **dos** transacciones:
- La **fraudulenta** → `fetch → score (SOSPECHOSA) → investigate → draft` → imprime un **SAR redactado**.
- La **legítima** → `fetch → score (OK) → close` → cierra el caso.

🎉 ¡Tu agente ejecuta un **workflow multi-paso** orquestando modelo + RAG + LLM!

### 6.1 — Visualizar el grafo 🖱️ (para el portafolio)
Añade al final del `__main__`:
```python
    print(agent.get_graph().draw_ascii())       # diagrama en la terminal
    # o, para un diagrama bonito:
    # print(agent.get_graph().draw_mermaid())   # pega el resultado en mermaid.live
```
Imprime el diagrama del grafo. Captúralo para tu README. 📸

> 💡 **LangGraph Studio (visual, opcional):** existe una app de escritorio, **LangGraph Studio**, que ejecuta tu agente mostrando el **grafo animándose paso a paso** (qué nodo corre, el estado en cada punto). Es la forma más visual de depurar agentes y queda espectacular en una demo. Requiere estructurar el proyecto con un `langgraph.json`; si te animas, es un gran extra para el portafolio.

### ✅ Checkpoint 6
El agente corre para ambas transacciones y produce un SAR para la sospechosa.

---

## 7. Human

> 🆕 **Patrón senior:** en banca, una acción crítica (emitir un SAR) **no se automatiza al 100%**; un humano la aprueba. LangGraph lo soporta con **interrupts** + **checkpointer**.

Versión con pausa antes de redactar el SAR:
```python
from langgraph.checkpoint.memory import MemorySaver

# compilar con checkpointer e interrupción antes de 'draft'
agent = g.compile(checkpointer=MemorySaver(), interrupt_before=["draft"])

config = {"configurable": {"thread_id": "caso-001"}}
# 1) corre hasta el punto de interrupción
agent.invoke({"tx_id": int(fraud_ids[0])}, config)
# 2) aquí un humano revisa el score y las quejas...
input("Revisa el caso. Enter para aprobar la redacción del SAR...")
# 3) reanuda
result = agent.invoke(None, config)
print(result["sar_draft"])
```
💡 **Para entrevista:** "Incluyo **human-in-the-loop** con interrupts de LangGraph: el agente pausa antes de acciones de alto riesgo y un analista aprueba. Esencial para cumplimiento en banca."

### ✅ Checkpoint 7
Entiendes (y puedes mostrar) cómo el agente pausa para aprobación humana.

---

## 8. React

> Hasta aquí construiste un **workflow** (tú defines los pasos). La otra forma es un **agente autónomo** que **decide** qué tool usar. LangGraph trae uno prefabricado.

Concepto (no hace falta implementarlo completo, pero entiéndelo para la entrevista):
```python
from langgraph.prebuilt import create_react_agent
from langchain_core.tools import tool

@tool
def score_tx(tx_id: int) -> str:
    """Puntúa el riesgo de fraude de una transacción por su id."""
    ...

@tool
def search_complaints(query: str) -> str:
    """Busca quejas de clientes similares a una descripción."""
    ...

agent = create_react_agent(llm, tools=[score_tx, search_complaints])
agent.invoke({"messages": [("user", "Investiga la transacción 3 y dime si es fraude")]})
```
💡 **Workflow vs ReAct (guion senior):** "Para procesos críticos y auditables (banca) prefiero un **workflow con LangGraph** — determinista y controlable. Para tareas exploratorias uso un **agente ReAct** que decide sus pasos. Sé cuándo usar cada uno." ← Esto es exactamente lo que un Senior AI Engineer responde.

### ✅ Checkpoint 8
Puedes explicar la diferencia entre workflow definido y agente ReAct autónomo, y cuándo usar cada uno.

---

## 9. Produccion

- **Tools reales:** en producción las tools llamarían a BigQuery (transacción real), al endpoint del modelo (Manual 06/07) y al RAG en pgvector — no a CSVs locales.
- **Observabilidad:** instrumenta el agente con **Langfuse** (Manual 05 §12) para ver **cada paso, decisión, latencia y costo** — crucial para depurar agentes.
- **Guardrails:** valida entradas/salidas y limita acciones (Manual 08) — un agente con tools es más poderoso y más riesgoso.

🔁 **En AWS:** equivalentes serían **Bedrock Agents** (agentes gestionados) o **Step Functions** para workflows. Mismo concepto de orquestación de IA.

### ✅ Checkpoint 9
Puedes describir cómo se vería este agente en producción (tools reales + tracing + guardrails).

---

## 10. Commit

🖱️ **Por la UI (VS Code):** Source Control → commit → push (con el `.gitignore` de abajo).

⌨️ **Por CLI:** añade al `.gitignore`:
```
# Agents
agents/*.joblib
agents/*.csv
```
```powershell
git add agents/fraud_agent.py .gitignore
git commit -m "Manual 05B: Agente Investigador de Fraude con LangGraph (workflow multi-paso + human-in-the-loop)"
git push origin main
```

### ✅ Checkpoint 10
En GitHub aparece `agents/fraud_agent.py` (sin modelo ni datos).

---

## 11. Checklist

- [ ] Entiendo qué es un agente, una tool y el patrón ReAct.
- [ ] Entiendo LangGraph: state, nodes, edges (condicionales), cycles.
- [ ] Modelo y muestra de transacciones disponibles en `agents/`.
- [ ] **Agente Investigador de Fraude** construido (5 nodos + arista condicional).
- [ ] El agente corre: fraude → SAR; legítima → cierra.
- [ ] Visualicé el grafo (draw_ascii/mermaid) para el portafolio.
- [ ] Entiendo **human-in-the-loop** (interrupts).
- [ ] Sé la diferencia **workflow vs agente ReAct** y cuándo usar cada uno.
- [ ] Sé cómo se llevaría a producción (tools reales, tracing, guardrails).
- [ ] Código commiteado.

Si todo está ✅ → **listo para el Manual 06: MLOps + CI/CD + Testing.**

---

## 12. Troubleshooting

| Problema | Causa | Solución |
|---|---|---|
| `joblib.load` falla | Falta xgboost/sklearn local | `pip install xgboost scikit-learn`. |
| Score raro / error de columnas | Features desalineadas | El `reindex(columns=FEATURES, fill_value=0)` lo maneja; confirma que el CSV viene del mismo mart. |
| Chroma no encuentra la colección | Ruta o nombre | Usa `persist_directory="../rag/chroma_db"` y `collection_name="complaints"`. |
| `langgraph` no importa | No instalado | `pip install langgraph`. |
| El agente siempre cierra (nunca sospechosa) | Umbral alto o tx legítimas | Usa `fraud_ids[0]`; revisa el umbral del modelo. |
| Ollama lento | Modelo grande | Normal en CPU; tu GPU lo acelera. |
| `draw_ascii` falla | Falta dependencia opcional | Usa `draw_mermaid()` o omítelo; es solo visual. |

---

## 13. Glosario

- **Agente de IA:** sistema donde un LLM decide y usa herramientas en varios pasos.
- **Tool:** función que el agente puede invocar.
- **ReAct:** patrón Reason+Act (razonar, actuar, observar, repetir).
- **Workflow vs agente autónomo:** pasos definidos por ti vs decididos por el LLM.
- **LangGraph:** framework para agentes/workflows como grafo de estado.
- **LangGraph Studio:** app visual para ejecutar y depurar agentes viendo el grafo.
- **State / Node / Edge:** estado compartido / paso / conexión (puede ser condicional).
- **Arista condicional:** rama del grafo según una decisión.
- **Human-in-the-loop:** pausa para aprobación humana (interrupt + checkpointer).
- **SAR:** Suspicious Activity Report (reporte de actividad sospechosa).
- **Bedrock Agents / Step Functions:** equivalentes de orquestación de IA en AWS.

---

> **⬅️ Anterior:** [Manual 05 — RAG](./05_rag_consultas_semanticas.md)
> **➡️ Siguiente:** Manual 06 — MLOps + CI/CD + Testing _(en construcción)_
