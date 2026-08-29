---
name: documentar-sesion
description: >-
  Documenta una sesión de trabajo en docs/sesiones/sesion-<fecha>/ siguiendo la
  convención del repo (carpeta por fecha, archivos NN_TEMA.md en español,
  00_RESUMEN_SESION.md + README índice, secciones de causa raíz/fixes/estado/
  pendientes). Úsala cuando
  pidan: documentar/cerrar la sesión, bitácora o diario de trabajo, registrar lo
  hecho, postmortem de la sesión, "document work session", session log/notes.
---

# documentar-sesion

Genera y valida la documentación de una **sesión de trabajo**. Toda la
documentación de sesión vive bajo **`docs/sesiones/`**, una carpeta por fecha
(`docs/sesiones/sesion-<YYYY-MM-DD>/`), más un índice maestro
`docs/sesiones/README.md` que lista todas las sesiones. El camino principal es el
script `session-doc.sh` (scaffold + validador). Todas las rutas son relativas a la
raíz del repo; el script resuelve la raíz con git, así que puede correrse desde
cualquier directorio.

## Uso (camino del agente)

1. **Scaffold** de la carpeta del día (idempotente — nunca sobreescribe):

   ```bash
   bash .claude/skills/documentar-sesion/session-doc.sh new
   ```

   (o con fecha explícita: `... new 2026-06-02`). Crea
   `docs/sesiones/sesion-<fecha>/` con `00_RESUMEN_SESION.md` y `README.md` desde
   plantilla, y añade la fila de la sesión al índice maestro
   `docs/sesiones/README.md`.

2. **Rellena** `00_RESUMEN_SESION.md` con lo real de la sesión (no inventes):
   qué se hizo, causa raíz/hallazgos **con su evidencia** (log, query, medición),
   tabla de cambios/fixes, estado al cierre, pendientes, decisiones.

3. **Docs temáticos**: para hallazgos o análisis extensos, crea archivos
   `NN_TEMA.md` (`01_`, `02_`, …) y **agrégalos a la tabla del `README.md`**.

4. **Hallazgos durables → memoria**: lo que sirva en sesiones futuras (causa raíz
   real, decisiones de arquitectura, gotchas) va también en `MEMORY.md`, no solo
   en los docs de sesión.

5. **Valida** antes de cerrar:

   ```bash
   bash .claude/skills/documentar-sesion/session-doc.sh check
   ```

   Reporta `PASS/WARN/FAIL`. Sale ≠0 si falta un obligatorio
   (`00_RESUMEN_SESION.md` o `README.md`).

## Convenciones

- **Una carpeta por fecha**, no por tema, bajo `docs/sesiones/`:
  `docs/sesiones/sesion-2026-06-02/`. El índice maestro `docs/sesiones/README.md`
  lista todas las sesiones (lo mantiene `new`).
- **Archivos temáticos numerados**: `NN_NOMBRE_EN_MAYUSCULAS.md` (`00_` es el
  resumen). El `README.md` es el índice (tabla archivo→contenido + TL;DR).
- **Español con acentuación correcta**; nunca sustituir acentos por ASCII.
- **Fechas absolutas** (`2026-06-02`), nunca relativas ("hoy", "ayer"). El `check`
  avisa si aparecen.
- **Correcciones que supersedan**: si un dato de un doc previo resultó incorrecto,
  añade una nota `> ⚠️ CORREGIDO <fecha>: ...` y apunta al doc nuevo, en vez de
  borrar el histórico.
- **Tablas** para estados, inventarios y listas de fixes; **referencias cruzadas**
  por ruta relativa entre docs.

## Qué va en docs de sesión vs MEMORY.md

- **Docs de sesión** = narrativa puntual de *esta* sesión (qué pasó, en qué orden,
  resultados, números al cierre).
- **MEMORY.md** = hecho **durable y reutilizable** (causa raíz confirmada, decisión
  con su porqué, convención). Si algo solo importa para esta sesión, va en los
  docs; si lo querrás recordar la próxima vez, va en memoria.

## Gotchas

- `new` es **idempotente**: re-correrlo imprime `= existe (no se toca)` y no pisa
  nada. Seguro para actualizar la carpeta del día.
- El script **resuelve la raíz del repo con `git rev-parse`**; funciona desde
  cualquier cwd. Sin git, cae a su propia ubicación (`../../..`).
- El `check` marca `WARN` (no `FAIL`) para archivos auxiliares fuera de la
  convención (p. ej. `*.jsonl`, postmortems con nombre libre): es a propósito,
  esos artefactos conviven con los `NN_`.
- Solo lee/escribe bajo `docs/`. No toca código del proyecto.

## El driver

`session-doc.sh` (en este mismo directorio) es el entregable; este `SKILL.md` es
su manual. Subcomandos: `new [YYYY-MM-DD]` (scaffold) y `check [YYYY-MM-DD]`
(validador). Default de fecha: hoy (`date +%F`).
