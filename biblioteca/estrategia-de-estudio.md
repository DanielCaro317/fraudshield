# 🧭 Estrategia de estudio — amplitud primero, profundidad desde el núcleo

> Cómo recorrer esta biblioteca sin caer en la *ilusión de competencia*. Dos fases y un orden de prioridad radial.

---

## Las dos fases

### Fase 1 — Amplitud (el mapa completo)
**Qué:** ejecuta los manuales paso a paso, en su orden natural (00 → 09), y **construye el proyecto entero end-to-end**.
**Objetivo:** una primera vista completa de cómo encaja todo. No es dominar; es *ver el sistema*.
**Regla anti-ilusión:** por cada manual, lee antes la **🧠 Idea central** de su ficha en el mapa (2-4 frases). Así el pase no es copiar a ciegas.
**Resultado:** un sistema que funciona + el mapa mental para saber *dónde* cavar hondo.

### Fase 2 — Profundidad (dominio real)
**Qué:** por cada tema, aplica el método completo → 🎯 ruta de lectura → 📘 doc oficial → 🔀 variantes (rompe y reconstruye) → registra decisiones y errores.
**Orden:** **desde el núcleo (IA-RAG) hacia afuera**, siguiendo el diagrama de abajo. No linealmente por manual.
**Objetivo:** poder *justificar cada decisión y cambiarla si el requisito cambia*.

> ⚠️ La Fase 1 sin la Fase 2 = ilusión de competencia. La Fase 2 es la que convierte "lo hice" en "lo domino".

---

## 🎯 Diagrama de prioridad (radial, de dentro hacia afuera)

La profundidad de estudio es **máxima en el centro** y va bajando a "lo justo" en el borde. Cuanto más al centro, más rápido cambia la doc y más te sube de nivel.

```
        ┌──────────────────────────────────────────────────────────┐
        │  ⚪ ANILLO 5 · Agnósticas (intersección ML ↔ Ing. Soft.)  │
        │     SQL · Python · IAM/cloud · Docker · Terraform · Git   │
        │   ┌──────────────────────────────────────────────────┐   │
        │   │  🟢 ANILLO 4 · Ingeniería de datos               │   │
        │   │     BigQuery/S3 · dbt (ELT) · Airflow            │   │
        │   │   ┌──────────────────────────────────────────┐   │   │
        │   │   │  🟡 ANILLO 3 · ML clásico (fraude)       │   │   │
        │   │   │     Desbalance/AUC-PR · XGBoost · SHAP   │   │   │
        │   │   │   ┌──────────────────────────────────┐   │   │   │
        │   │   │   │  🟠 ANILLO 2 · LLMOps/producción │   │   │   │
        │   │   │   │     Eval-gates · Deploy · Tracing│   │   │   │
        │   │   │   │   ┌──────────────────────────┐   │   │   │   │
        │   │   │   │   │  🔴 ANILLO 1 · Confianza │   │   │   │   │
        │   │   │   │   │   Evaluación · Guardrails│   │   │   │   │
        │   │   │   │   │   · Fine-tuning          │   │   │   │   │
        │   │   │   │   │   ┌──────────────────┐   │   │   │   │   │
        │   │   │   │   │   │   🫀 NÚCLEO      │   │   │   │   │   │
        │   │   │   │   │   │  RAG · Embeddings│   │   │   │   │   │
        │   │   │   │   │   │  LLMs · Agentes  │   │   │   │   │   │
        │   │   │   │   │   └──────────────────┘   │   │   │   │   │
        │   │   │   │   └──────────────────────────┘   │   │   │   │
        │   │   │   └──────────────────────────────────┘   │   │   │
        │   │   └──────────────────────────────────────────┘   │   │
        │   └──────────────────────────────────────────────────┘   │
        └──────────────────────────────────────────────────────────┘
      Profundidad:  MÁXIMA en el centro  ───────────►  "lo justo" en el borde
      Doc cambia:   rápido (leer fresco) ───────────►  lento (estable)
```

---

## Orden de profundización (Fase 2) y por qué

| Prioridad | Anillo | Temas | Dónde en los mapas | Por qué esta prioridad |
|:---:|---|---|---|---|
| **1** | 🫀 Núcleo | RAG, embeddings, LLMs+prompting, agentes (LangGraph) | GCP [5.1](gcp-fraudshield/mapa-documentacion.md)–[5.3](gcp-fraudshield/mapa-documentacion.md), [6.1](gcp-fraudshield/mapa-documentacion.md) · AWS [1.1](aws-banking-copilot/mapa-documentacion.md), [2.2](aws-banking-copilot/mapa-documentacion.md)–[3.1](aws-banking-copilot/mapa-documentacion.md), [6.1](aws-banking-copilot/mapa-documentacion.md) | Tu mayor diferenciador, lo más difícil de fingir, la doc que más rápido cambia. |
| **2** | 🔴 Confianza de la IA | evaluación (RAGAS/Bedrock Eval), guardrails/seguridad de IA, fine-tuning | GCP [5.4](gcp-fraudshield/mapa-documentacion.md), [8.2](gcp-fraudshield/mapa-documentacion.md), [4.7](gcp-fraudshield/mapa-documentacion.md) · AWS [4.1](aws-banking-copilot/mapa-documentacion.md), [5.1](aws-banking-copilot/mapa-documentacion.md) | Hace *producible* el núcleo. Son justo tus 3 puntos ciegos (eval, CI/CD, seguridad). |
| **3** | 🟠 LLMOps / producción | tracing (Langfuse), CI/CD con eval-gates, despliegue (Cloud Run/Lambda) | GCP [7.1](gcp-fraudshield/mapa-documentacion.md)–[7.3](gcp-fraudshield/mapa-documentacion.md) · AWS [7.1](aws-banking-copilot/mapa-documentacion.md), [7.4](aws-banking-copilot/mapa-documentacion.md) | Lleva el núcleo a producción con calidad continua. |
| **4** | 🟡 ML clásico | clases desbalanceadas, XGBoost/BQML, SHAP | GCP [4.2](gcp-fraudshield/mapa-documentacion.md)–[4.6](gcp-fraudshield/mapa-documentacion.md) | El corazón del lado "detección de fraude ML". Vital, pero más estándar y estable. |
| **5** | 🟢 Ingeniería de datos | dbt, Airflow, BigQuery/almacenamiento | GCP [1.2](gcp-fraudshield/mapa-documentacion.md), [2.1](gcp-fraudshield/mapa-documentacion.md), [3.1](gcp-fraudshield/mapa-documentacion.md) | La base que alimenta todo. Se entiende mejor **después** de ver para qué sirve. |
| **6** | ⚪ Agnósticas | SQL, Python, IAM/cloud, Docker, Terraform, Git, React | GCP [0.1](gcp-fraudshield/mapa-documentacion.md)–[0.3](gcp-fraudshield/mapa-documentacion.md), [7.x](gcp-fraudshield/mapa-documentacion.md) · AWS [0.x](aws-banking-copilot/mapa-documentacion.md) | Transferibles y estables. "Lo justo" para construir; profundiza solo si un requisito lo pide. |

> **Regla de dedo:** el tiempo de estudio profundo por tema debería *decrecer* del anillo 1 al 6. Un día entero en RAG/embeddings vale más que un día en SQL (que ya conoces y cambia poco).

---

## Cómo se conecta con el método

- La **Fase 1** = el paso *"implementación mínima"* del PDF (curso corto → doc → **construir**).
- La **Fase 2** = los pasos *"variantes → producción/seguridad/eval → documentación propia"*, y las patas que aún faltan: **registrar cada decisión y cada error** (futuras plantillas en `00_metodo/`).
- El **diagrama** decide el *orden*; los **mapas** dan el *contenido* (idea central, ruta de lectura, doc, libros, variantes).

> Este orden prioriza *dominio que sube de nivel*, no *cobertura*. Está bien quedarse en "lo justo" en el borde: un ingeniero senior no domina todo por igual — domina el núcleo y sabe *dónde buscar* el resto.
