# 🧰 00 · Método — plantillas reutilizables

> Los **mapas** te dicen *qué estudiar* y la **estrategia** *en qué orden*. Estas plantillas operan las patas del método que faltaban del [PDF](../README.md): **registrar cada decisión**, **registrar cada error** y producir **evidencia de dominio**.
>
> Recuerda la fórmula: *Documentación + problema propio + experimentación + **errores** + **explicar decisiones**.* Las dos últimas viven aquí.

---

## Las 3 plantillas y cuándo usarlas

| Plantilla | Cuándo la usas | Qué te da |
|---|---|---|
| [`plantilla-ficha-dominio.md`](./plantilla-ficha-dominio.md) | Al **terminar** de profundizar un tema (Fase 2 de la [estrategia](../estrategia-de-estudio.md)) | Tu "manual profesional" del tema = **evidencia de que lo dominas** (las 10 secciones del PDF). |
| [`plantilla-registro-decisiones.md`](./plantilla-registro-decisiones.md) | Cada vez que **eliges** entre alternativas mientras construyes (ADR-lite) | Registro de *por qué* elegiste algo → te entrena a *justificar arquitectura*. |
| [`plantilla-registro-errores.md`](./plantilla-registro-errores.md) | Cada vez que algo **falla** y lo resuelves | Bitácora de causa raíz + lección → el artefacto de **mayor apalancamiento** de aprendizaje. |

---

## Cómo usarlas (flujo)

1. **Copia** la plantilla a la carpeta del proyecto correspondiente, no la edites aquí.
2. Renombra con un slug claro.
3. Rellénala en el momento (una decisión/error se registra *cuando ocurre*, no "después").

**Convención de ubicación** (las instancias llenas viven por proyecto):

```
biblioteca/
├── 00_metodo/                     ← las plantillas (esto; no se llenan aquí)
├── gcp-fraudshield/
│   ├── mapa-documentacion.md
│   ├── fichas/                    ← ficha-rag.md, ficha-dbt.md, …
│   ├── decisiones/                ← ADR-001-vector-store.md, …
│   └── errores/                   ← ERR-001-data-leakage.md, …
└── aws-banking-copilot/
    ├── mapa-documentacion.md
    ├── fichas/  ·  decisiones/  ·  errores/
```

> Crea las subcarpetas `fichas/`, `decisiones/`, `errores/` cuando escribas la primera de cada tipo.

---

## Por qué esto cierra el círculo

- La **ficha de dominio** es la *prueba real de aprendizaje* del PDF: no "terminé el curso", sino *"puedo recibir requisitos distintos, consultar la doc, diseñar alternativas, justificar una arquitectura y construirla"*.
- El **registro de decisiones** convierte cada elección en criterio explícito (lo que un arquitecto hace).
- La **bitácora de errores** captura el aprendizaje que de otro modo se evapora: cada error resuelto = una lección que no repites.

> No es burocracia. Es la diferencia entre *hacer que funcione una vez* y *entender el sistema*.
