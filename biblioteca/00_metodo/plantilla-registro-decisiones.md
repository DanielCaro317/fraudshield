<!--
PLANTILLA · REGISTRO DE DECISIONES (ADR-lite)
Un ADR = Architecture Decision Record. Registra UNA decisión técnica cuando la tomas.
Cópiala a  <proyecto>/decisiones/ADR-<###>-<slug>.md  (una decisión por archivo) y numéralas.
Objetivo: entrenarte a JUSTIFICAR arquitectura, no solo configurarla.
Abajo tienes la plantilla en blanco + un ejemplo lleno. Borra estos comentarios al terminar.
-->

# ADR-`<###>` · `<Título corto de la decisión>`

- **Fecha:** `<AAAA-MM-DD>`
- **Estado:** ☐ propuesta · ☐ **aceptada** · ☐ reemplazada por ADR-`<###>` · ☐ descartada
- **Proyecto / Capa:** `<gcp-fraudshield | aws-banking-copilot>` · `<##>`

## Contexto
*¿Qué problema o requisito me obliga a decidir? ¿Qué restricciones hay (costo, latencia, tiempo, skills, cuotas)?*
>

## Opciones consideradas
| Opción | Pros | Contras |
|---|---|---|
| A · `<…>` | | |
| B · `<…>` | | |
| C · `<…>` | | |

## Decisión
*Elijo **`<opción>`**.*
>

## Justificación
*¿Por qué esta y no las otras? Ata la razón a las restricciones del contexto.*
>

## Consecuencias (trade-offs)
*Qué gano, qué sacrifico, qué deuda o riesgo asumo, y qué haría falta para revertirla.*
>

---
---

# 📎 Ejemplo lleno (referencia — bórralo en tu copia)

# ADR-001 · Vector store para el RAG de quejas

- **Fecha:** 2026-07-27
- **Estado:** aceptada
- **Proyecto / Capa:** gcp-fraudshield · 5.1

## Contexto
Necesito almacenar ~10k embeddings de quejas para búsqueda semántica. Estoy en fase de prototipo, con crédito gratis limitado y prioridad en aprender el flujo RAG, no en operar infraestructura. El volumen es pequeño y las consultas, esporádicas.

## Opciones consideradas
| Opción | Pros | Contras |
|---|---|---|
| A · ChromaDB (local) | Cero costo, simple, corre en el notebook, ideal para entender el mecanismo | No escala, no gestionado, no "de producción" |
| B · Vertex AI Vector Search | Gestionado, escala a millones, ScaNN | Costo de índice encendido, más setup, sobra para 10k |
| C · pgvector (Cloud SQL) | SQL familiar, transaccional | Levanta una instancia (costo/hora), overkill ahora |

## Decisión
Elijo **ChromaDB (A)** para el prototipo, con la interfaz de retrieval abstraída para poder migrar.

## Justificación
En fase de aprendizaje el objetivo es *entender chunking, embeddings y top-k*, no operar un índice. Con 10k vectores el rendimiento sobra y el costo cero me deja iterar sin miedo. Vertex Vector Search sería la elección al escalar a millones o al exigir latencia baja en producción.

## Consecuencias (trade-offs)
Gano velocidad de iteración y cero costo; sacrifico el "sello de producción" y tendré que migrar al escalar. Mitigo la deuda dejando el retriever detrás de una interfaz → migrar a Vertex sería cambiar una clase, no el pipeline. Ver ficha `fichas/ficha-rag.md` y variante en el mapa 5.1.
