<!--
PLANTILLA · BITÁCORA DE ERRORES
Registra un error CUANDO lo resuelves (no "después"). Es el artefacto que más te hace aprender.
Cópiala a  <proyecto>/errores/ERR-<###>-<slug>.md  (uno por error) y numéralos.
Regla: no pases al siguiente paso sin escribir la CAUSA RAÍZ y la LECCIÓN. El síntoma no basta.
Abajo: plantilla en blanco + ejemplo lleno. Borra estos comentarios al terminar.
-->

# ERR-`<###>` · `<Título corto del error>`

- **Fecha:** `<AAAA-MM-DD>` · **Proyecto / Capa:** `<gcp-fraudshield | aws-banking-copilot>` · `<##>`
- **Severidad:** ☐ molestia · ☐ bloqueante · ☐ **silencioso (parecía funcionar)** ← los más peligrosos
- **Tiempo perdido:** `<~Xh>`

## 🔴 Síntoma
*¿Qué observé? Mensaje de error exacto, comportamiento raro, o métrica sospechosa.*
>

## 🔍 Contexto
*¿Qué estaba haciendo? ¿Qué cambió justo antes?*
>

## 🎯 Causa raíz
*El porqué **real**, no el síntoma. Si dudas, aún no la encontraste.*
>

## 🛠️ Solución
*Qué hice exactamente para arreglarlo (comando, cambio, config).*
>

## 🧠 Lección / prevención
*¿Cómo evito que vuelva a pasar? ¿Qué señal lo habría detectado antes? ¿Va a la ficha de dominio (§7)?*
>

---
---

# 📎 Ejemplo lleno (referencia — bórralo en tu copia)

# ERR-001 · El modelo de fraude daba AUC 0.99 (demasiado bueno)

- **Fecha:** 2026-07-27 · **Proyecto / Capa:** gcp-fraudshield · 4
- **Severidad:** silencioso (parecía funcionar) · **Tiempo perdido:** ~3h

## 🔴 Síntoma
El clasificador de fraude reportaba AUC-ROC ≈ 0.99 y AUC-PR ≈ 0.97 en validación. Sospechosamente perfecto para un problema de fraude real.

## 🔍 Contexto
Entrené un XGBoost con todas las columnas del dataset transformado por dbt, incluida una feature derivada `is_flagged_fraud` y el balance posterior a la transacción.

## 🎯 Causa raíz
**Fuga de datos (data leakage):** incluí features que solo existen *después* de conocer el resultado del fraude (`is_flagged_fraud` y el balance final). El modelo no aprendía a *predecir* fraude, sino a *leer* la respuesta que ya estaba en los datos.

## 🛠️ Solución
Quité las columnas que no estarían disponibles *en el momento de la predicción* (antes de saber si es fraude). Reentrené solo con features conocidas al llegar la transacción. El AUC-PR cayó a ~0.72 — realista y honesto.

## 🧠 Lección / prevención
Antes de entrenar, preguntar de **cada** feature: *"¿existiría este valor en el instante en que necesito predecir?"* Si no, es fuga. Añadir un check de "features disponibles en inferencia" al pipeline dbt. → Va a `fichas/ficha-ml-fraude.md` §7 (errores comunes) y refuerza el mapa 4.1/4.3.
