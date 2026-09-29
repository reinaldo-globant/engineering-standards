# ADR por repo y registro de intentos descartados

**Fecha:** 2026-09-28
**Estado:** aprobado, pendiente de plan de implementación

## Problema

El skill ya pide registrar *"dead ends already tried, with the reason they failed"*
(`references/repo-memory.md:84`) y trae un ejemplo trabajado de rechazo
(`repo-memory.md:76`). El contenido está previsto. Lo que falta es la mecánica que lo
preserva, y hoy hay tres fugas por las que el contexto se pierde entre sesiones:

1. **No existe ADR.** Cero menciones en el repo. Las decisiones viven como entradas sueltas
   de `MEMORY.md`: sin número, sin estado, sin cadena de reemplazo. La deliberación del paso
   `DECIDE` (`SKILL.md:49`) y el bloque `Option A / Option B / Recommendation` de §6 se
   descartan al cerrar la sesión — justo el material que evita repetir el análisis.

2. **Una regla poda lo que hay que conservar.** `repo-memory.md:94`: *"if an entry is still
   true but no longer relevant to anything in the repo, it goes."* Un intento descartado es
   *siempre* irrelevante hasta el día en que alguien lo vuelve a intentar. Esa es
   precisamente su función, y la regla de sizing lo borra.

3. **El gate de escritura llega tarde.** `repo-memory.md:90` exige propose → approve → write
   para toda entrada. El momento en que un intento falla es el momento en que nadie para a
   pedir aprobación, así que el fallo no se registra nunca.

## Diseño

### Pieza 1 — `docs/adr/`

Directorio por repositorio, un archivo por decisión, nombrado `NNNN-slug.md` con numeración
correlativa de cuatro dígitos empezando en `0001`.

**Gate por tier** (reusa el right-sizing de §2, no inventa un criterio nuevo):

| Tier | Cuándo nace un ADR |
|---|---|
| Core | En cada fork del paso `DECIDE`: se evaluó más de una opción viable y una ganó |
| Evolving | Solo si la decisión también obliga a tocar `ARCHITECTURE.md` |
| Throwaway | Nunca. Tampoco se crea `docs/` |

**Plantilla:**

```markdown
# 0002 — Postgres sobre Mongo para el catálogo
Status: Accepted
Date: 2026-09-28

## Contexto
La restricción que forzó la decisión. Una o dos frases.

## Decisión
Qué se hace. En presente, en imperativo.

## Alternativas descartadas
- **Mongo** — las queries del catálogo son relacionales en 4 de 5 casos; probado en spike,
  3 joins quedaban en capa de aplicación.
- **DynamoDB** — coste por lectura x8 al volumen proyectado.

## Consecuencias
Qué se vuelve fácil y qué se vuelve caro por haber elegido esto.
```

`Status` admite dos valores: `Accepted` o `Superseded by NNNN`. No hay `Proposed` ni
`Deprecated` — un ADR se escribe cuando la decisión ya está tomada.

**Inmutabilidad:** un ADR no se edita ni se borra. Cuando una decisión se revierte, el ADR
viejo pasa a `Superseded by NNNN` y nace uno nuevo que explica por qué. Ese rastro es el
producto: si el siguiente agente propone Mongo, el 0002 está ahí con la medición.

**Enlace con §6:** el bloque `Decision required: / Option A / Option B / Recommendation` que
§6 ya obliga a producir **es** el borrador del ADR. Cuando el usuario responde el fork, ese
texto se convierte en el archivo — la opción perdedora va a `## Alternativas descartadas`
con el motivo. No hay trabajo extra: hoy esa deliberación se tira.

### Pieza 2 — `docs/MEMORY.md`, sección `## Descartados`

Sección al final del archivo, append-only, **explícitamente exenta de la regla de sizing**.

```markdown
## Descartados

<!-- Append-only. Nunca se poda, aunque parezca irrelevante: su valor es justo que nadie lo recuerde. -->

### 2026-09-28 — `asyncio.to_thread` para el parser de CSV
Peor que el código síncrono: el GIL no se suelta durante la lectura. Medido 1.4x más lento
(12.1s vs 8.6s sobre el fixture de 400k filas).
**Reconsiderar si:** se cambia a un parser que libere el GIL (polars, pyarrow).
```

Tres partes obligatorias: qué se intentó · por qué falló, con evidencia · `Reconsiderar si:`.

`Reconsiderar si:` no es opcional. Un descarte sin condición de reapertura se lee como dogma
y bloquea trabajo legítimo dentro de dos años. Si no se puede nombrar la condición, la
entrada dice `Reconsiderar si: nunca — [razón estructural]`.

**Descarte vs ADR:** el ADR registra una decisión *tomada* entre opciones evaluadas en
diseño. El descarte registra un intento *ejecutado* que falló. Si se escribió código y se
revirtió, es un descarte. Si se comparó en el papel y se eligió, es un ADR. Un mismo fork
puede producir ambos, y entonces el ADR enlaza la entrada por fecha.

### Pieza 3 — El gate asimétrico

| Regla actual | Nueva |
|---|---|
| `repo-memory.md:94` — *"no longer relevant → it goes"* | Aplica a todo `MEMORY.md` **excepto** `## Descartados`, que es append-only |
| `repo-memory.md:90` — propose → approve → write, para todo | **Asimétrico.** Descarte: se escribe en el acto, sin preguntar. ADR: mantiene el gate |
| `repo-memory.md:8-13` — checklist de entrada | Añadir paso: `¿Existe docs/adr/? → léelo antes de proponer arquitectura` |

**Por qué asimétrico:** un descarte es un hecho observado — se ejecutó X, falló por Y, aquí
está el error. No requiere criterio del usuario, requiere evidencia. Un ADR es un juicio
sobre qué conviene al proyecto, y ese sigue siendo del usuario.

**Requisito que sustituye al gate:** un descarte solo se escribe con evidencia concreta — el
mensaje de error, el número medido, el test que falla. Sin evidencia no hay entrada. *"No
funcionó"* no es un descarte, es una opinión, y una opinión escrita como hecho envenena el
archivo para todas las sesiones siguientes.

## Cambios por archivo

Solo el source of truth y el generador. `.cursor/`, `.github/` y `AGENTS.md` son artefactos.

### `skills/engineering-standards/references/repo-memory.md`

- Título y párrafo de apertura: pasan de tres artefactos a cuatro (ARCHITECTURE, MEMORY, ADR,
  registry).
- Checklist "Entering a repository" (L8-13): nuevo paso para `docs/adr/`.
- Nueva sección `## docs/adr/` entre `## docs/ARCHITECTURE.md` y `## docs/MEMORY.md`: gate por
  tier, plantilla, regla de inmutabilidad, enlace con §6.
- Sección `## docs/MEMORY.md`: añadir `## Descartados` al ejemplo, con el campo
  `Reconsiderar si:`.
- Writing rule (L90): reescribir como regla asimétrica.
- Sizing rule (L94): exceptuar `## Descartados`.

### `skills/engineering-standards/SKILL.md`

- L41 (`CONTEXT`): añadir `docs/adr/` a los archivos que se leen al entrar.
- L57-58 (`RECORD`): tres salidas en vez de dos — estructura → `ARCHITECTURE.md` · decisión
  con fork → ADR · intento abandonado → `## Descartados`.
- §6, tras el bloque de formato: una línea enlazando la decisión resuelta con el ADR.
- §11 (tabla de approval gates): la fila de `MEMORY.md` se matiza — las entradas de
  `## Descartados` quedan fuera del gate; se añade fila para el ADR.
- §12: `docs/adr/` entra en la tabla de artefactos y en el checklist de entrada.

### `scripts/build.sh`

- Heredoc de `AGENTS.md`: mencionar `docs/adr/` en el párrafo de contexto de repositorio.
- Checks de generación: añadir un `grep` que verifique que `docs/adr/` sobrevive a la
  concatenación, en la misma forma que los tres needles de las leyes de hierro.

### Regeneración

`./scripts/build.sh` reescribe `.cursor/rules/*.mdc`,
`.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` y `AGENTS.md`.

## Verificación

1. `./scripts/build.sh` termina en `ok:` — sus propios checks son la prueba de que las reglas
   nuevas sobrevivieron a la generación.
2. `grep -rl 'docs/adr/' .cursor .github AGENTS.md` devuelve los cuatro artefactos.
3. `git diff --stat` no muestra cambios en artefactos generados que no vengan de un cambio en
   `skills/` o `scripts/build.sh`.
4. Lectura del `.mdc` generado: la sección `## docs/adr/` aparece completa y con la plantilla
   intacta, sin truncar por el `strip_frontmatter`.

## Fuera de alcance

Se dejan fuera deliberadamente, con su condición de entrada:

- **Script `new-adr.sh`** — un archivo numerado es un archivo numerado. Añadir si la
  numeración empieza a colisionar entre ramas.
- **`docs/adr/README.md` como índice** — añadir cuando `ls docs/adr/` deje de ser legible,
  alrededor de 15 ADRs.
- **Campos `Deciders`, `Consulted`, `Tags`** — añadir si el repo lo trabaja más de un equipo.
- **Estados `Proposed` / `Deprecated`** — el gate de aprobación ya cubre el estado propuesto;
  no hace falta materializarlo en el archivo.
- **Migración de entradas existentes de `MEMORY.md` a ADR** — los repos que ya tienen memoria
  se quedan como están. La regla aplica desde la siguiente decisión.
