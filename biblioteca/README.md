# 📚 Biblioteca profesional de Ingeniería de Datos e IA

> Mi mapa de aprendizaje **anclado a proyectos reales**, no a cursos genéricos.
> La construyo alrededor de lo que ya estoy construyendo: [`gcp-fraudshield/`](../gcp-fraudshield/) y [`aws-banking-copilot/`](../aws-banking-copilot/).

---

## 🎯 Por qué existe esta carpeta (el diagnóstico)

Los cursos enseñan a **repetir una solución**, no a **resolver una clase de problemas**. El tutor ya decidió por ti la arquitectura, los servicios, los parámetros y "el camino correcto". Mientras lo sigues, todo funciona y sientes que aprendes. Pero cuando cambia **una sola variable** —otro modelo, otro vector store, autenticación, costos, permisos, escala— el guion desaparece y vuelve la sensación de estar perdido. Eso es la **ilusión de competencia**.

La documentación oficial es distinta porque te obliga a entender la herramienta **como un sistema**: qué componentes existen, qué responsabilidad tiene cada uno, cuáles son las alternativas, qué límites y cuotas hay, qué decisiones son obligatorias y cuáles opcionales.

Pero la documentación **sola** tampoco basta. El aprendizaje profesional real es:

> **Documentación + problema propio + experimentación + errores + explicar decisiones.**

Esta biblioteca es la infraestructura de ese método.

---

## 🧭 El método (la ruta de estudio)

Para cada herramienta / arquitectura, el orden es:

```
Curso corto (orientación)  →  Documentación oficial  →  Implementación mínima
   →  Variantes (romper y reconstruir)  →  Producción, seguridad y evaluación
   →  Documentación propia (evidencia de dominio)
```

- El **curso** es solo el mapa inicial, no el centro.
- La **documentación oficial** es el centro de gravedad.
- Los **manuales** de cada proyecto (`*/manuales/`) son la *implementación mínima* + la *documentación propia*: el artefacto que prueba que dominas el tema.
- Este **mapa de documentación** es lo que faltaba: la capa que te dice **qué leer, en qué orden, y por qué**, antes y durante la construcción.

**La prueba real de aprendizaje** no es *"terminé el curso"*, sino poder decir:

> *"Puedo recibir requisitos distintos, consultar la documentación, diseñar alternativas, justificar una arquitectura y construirla."*

---

## 📖 Los 4 tipos de fuente (y cómo los separo)

Vengo de finanzas, donde bastaba con *"el Samuelson para economía"*. En TI el centro es distinto —es la **documentación oficial**— pero los libros y papers siguen dando la base conceptual que la doc da por supuesta. Por eso cada ficha separa cuatro capas:

| Símbolo | Capa | Qué es | Cuándo la uso |
|---|---|---|---|
| 📘 | **Documentación oficial** | La fuente de verdad. Se subdivide en **① Esencial** (leer sí o sí), **② Referencia** (consultar mientras implementas), **③ Avanzada** (producción, optimización, arquitectura). | Siempre. Es el centro. |
| 📚 | **Libros** | Solo **nombre + autor** (los busco en la biblioteca universitaria). Dan la teoría y el modelo mental que la doc asume. | Para entender *por qué*, no solo *cómo*. |
| 📄 | **Artículos / papers** | El paper fundacional o el artículo que explica una idea mejor que nadie. | Para conceptos clave y decisiones de diseño. |
| 🎓 | **Curso / video** | **Solo** cuando explica algo que la documentación no hace bien. | Orientación inicial o temas muy visuales. |

Además, cada componente trae 🔀 **Decisiones y variantes**: las preguntas de arquitecto (*"¿por qué esto y no la alternativa?"*) que convierten la lectura en criterio.

---

## 🗺️ Anatomía de una ficha de componente

Cada componente del mapa sigue esta plantilla (pensada para *leer poco y decidir bien*):

1. **🧠 Idea central** — el modelo mental en 2-4 frases: qué es *de verdad* y por qué está en el proyecto. Si solo lees esto, ya entiendes el rol de la pieza.
2. **🎯 Ruta de lectura** — por dónde empezar, en qué orden, qué leer a fondo y qué saltar, con **⏱️ tiempo estimado** de estudio.
3. 📘 **Documentación oficial** — ① esencial → ② referencia → ③ avanzada.
4. 📚 **Libros** (nombre + autor).
5. 📄 **Artículos / papers** clave.
6. 🎓 **Curso** (solo si aporta algo que la doc no da).
7. 🔀 **Decisiones y variantes** — el "rompe y reconstruye".

No es una lista de enlaces: es un **mapa conectado**
`Proyecto → arquitectura → componentes → documentación → práctica → variaciones → producción → evidencia de dominio`.

---

## 🧭 Estrategia de estudio (léela antes de los mapas)

[`estrategia-de-estudio.md`](./estrategia-de-estudio.md) — **cómo** recorrer la biblioteca: primero amplitud (construir todo end-to-end), luego profundidad **desde el núcleo IA-RAG hacia afuera** (diagrama de prioridad radial). El diagrama decide el *orden*; los mapas dan el *contenido*.

## 📂 Índice de mapas

| Proyecto | Mapa de documentación | Estado |
|---|---|---|
| **GCP — FraudShield** (datos + ML + RAG + agentes) | [`gcp-fraudshield/mapa-documentacion.md`](./gcp-fraudshield/mapa-documentacion.md) | 🟢 Listo |
| **AWS — Banking Copilot** (RAG/Bedrock/Guardrails) | [`aws-banking-copilot/mapa-documentacion.md`](./aws-banking-copilot/mapa-documentacion.md) | 🟢 Listo |

---

## 🧱 Enfoque (importante)

Esta biblioteca **ya no está atada a vacantes concretas** (Proxify/Ceiba caducaron). El objetivo es más amplio y a prueba de futuro: dominar **metodologías, variantes y herramientas** para poder responder a **cualquier** dominio o requisito que el mercado exija más adelante. Por eso el mapa prioriza *entender el sistema y sus alternativas* por encima de *seguir un único camino*.

> **Cada fuente se verifica contra la web al momento de escribirla** (sin métodos deprecados). Cada mapa lleva su fecha de verificación al pie.
