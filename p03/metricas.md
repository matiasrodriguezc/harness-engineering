# P03 · Continuidad con reinicios, una función a la vez

Pregunta del proyecto: cuando la sesión se corta a mitad de camino, ¿el agente se dispersa entre varias funciones o pierde el estado? ¿Marca funciones como `pass` sin evidencia?

**Funciones a implementar (4):** división de documentos en fragmentos (chunking), extracción de metadatos, estado de indexación en la barra de estado y preguntas y respuestas con citas.

**Cómo se simulan los reinicios:** cada sesión tiene un tope de gasto (`--max-budget-usd`). Al llegar al tope, la sesión se corta a mitad de trabajo, como cuando se acaba el contexto, y arranca una sesión nueva que solo sabe lo que quedó en los archivos. Se encadenan sesiones hasta que las 4 funciones estén en `pass` o hasta 5 sesiones. Script: `scripts/run-multi.sh`.

**Ajuste del diseño:** el primer intento usó un tope de US$1,20 y la corrida débil terminó las 4 funciones en una sola sesión de US$0,91, sin llegar al tope: no hubo reinicio. Ese intento se guardó en `baseline-sin-corte/` y las dos corridas comparadas usan un tope de **US$0,50** por sesión.

**Prompts (iguales en las dos corridas):** sesión 1, "Implement the remaining features of this project."; siguientes, "Continue working on this project."

**Modelo:** Claude Opus 5.5, modo no interactivo, `--permission-mode auto`, sin skills ni MCPs.

**Qué cambia entre corridas:**

| | Corrida 1 · harness débil | Corrida 2 · harness fuerte |
|---|---|---|
| `AGENTS.md` | Starter: comandos, capas, lista de funciones, una definición de "hecho" corta | Solution: reglas de inicio, **política de una función a la vez** (implementar, verificar, marcar con evidencia, commitear), dependencias entre funciones |
| `feature_list.json` | Sí (4 funciones `not-started`) | Sí (4 funciones `not-started`) |
| `init.sh` | No | Sí |
| `session-handoff.md` | No (el `AGENTS.md` dice que puede faltar) | Plantilla en blanco del curso |
| `claude-progress.md` | No | Vacío (solo el título) |
| `clean-state-checklist.md` | No | Sí, todo sin marcar |

**Diferencia con el curso:** el doc del P03 no trae protocolo ni métricas; el tope de gasto como simulación de reinicio es propio.

## Resultados por sesión

| Sesión | Corrida 1 · débil | Corrida 2 · fuerte |
|---|---|---|
| 1 | US$0,49 · 1:43 · 11 turnos · implementó las **4 funciones juntas** sin probarlas; las marcó como `implemented` (un estado que inventó), no `pass` | **Cortada por el tope** (US$0,52 · 2:10) · arregló el typecheck e hizo metadatos y chunking, **un commit por función**: el corte no perdió nada |
| 2 | US$0,29 · 1:17 · 10 turnos · escribió 3 tests de servicios, marcó las 4 como `pass`, commiteó y creó un `session-handoff.md` breve | US$0,36 · 1:09 · 11 turnos · retomó desde el traspaso, hizo **solo** el estado de indexación y commiteó |
| 3 | — | US$0,39 · 1:06 · 14 turnos · hizo preguntas y respuestas, corrió la checklist de cierre, encontró que falta un botón ("Show Chunks") y lo dejó escrito; aclaró que el proyecto **no** está completo |
| **Total** | **2 sesiones · 3:00 · 21 turnos · US$0,78** | **3 sesiones · 4:25 · 35 turnos · US$1,27** |
| Acciones antes de la primera edición | 4 y 4 | 3, 4 y 3 |

## Resultado final

| | Corrida 1 · débil | Corrida 2 · fuerte |
|---|---|---|
| Funciones en `pass` según `feature_list.json` | 4/4 | 4/4 |
| ¿Una función a la vez? | No: las 4 juntas en la sesión 1 | Sí: un commit por función (`historial-git.txt`) |
| ¿Se perdió trabajo al cortarse una sesión? | No hubo corte efectivo | No: la sesión cortada ya había commiteado lo hecho |
| `npm run check` / build | ✅ / ✅ | ✅ / ✅ (además `init.sh` pasa) |
| Tests automatizados | 3 (servicios) | Ninguno |
| **¿La interfaz puede usar la app?** (verificado por mí con `scripts/check-bridge.mjs`) | ❌ `window.knowledgeBase` es `undefined`: la ventana se ve pero no puede importar ni preguntar | ❌ igual |
| Estado para la próxima sesión | `session-handoff.md` de 12 líneas (lo creó por su cuenta) | `session-handoff.md`, `claude-progress.md` y hallazgos de la checklist |
| Tamaño del cambio (sin `package-lock.json`) | 14 archivos, +206 / −103 | 15 archivos, +205 / −109 |

**El intento sin corte** (`baseline-sin-corte/`, harness débil, tope US$1,20): 1 sesión, US$0,91, las 4 funciones juntas, sin tests. Desactivó el sandbox de Electron, lo que en P01 hacía que la interfaz funcionara; no lo verifiqué con `check-bridge.mjs` antes de borrar la carpeta.

## Fallas por capa

| Corrida | Falla | Capa |
|---|---|---|
| 1 y 2 | Las 4 funciones quedaron en `pass` con la interfaz desconectada: el preload importa `../shared/types` con el sandbox activo y no carga. Ninguna corrida lo detectó | Verificación: ni la Definition of Done ni la checklist exigen probar la app desde la interfaz; "la app abre" no es "la app funciona" |
| 1 | Implementó las 4 funciones juntas | Tarea / alcance (sin política de una función a la vez) |
| 2 | No escribió tests | Verificación (la Definition of Done no los pide) |
| 2 | Marcó en la checklist de cierre que "la app abre", pero no probó importar ni preguntar desde la ventana | Verificación (la checklist se llena leyendo código, no usando la app) |

## Conclusión

La política de **una función a la vez con commit por función** hizo lo que promete frente a los reinicios: la corrida fuerte fue la única con un corte real a mitad de trabajo (la sesión 1 llegó al tope) y **no perdió nada**, porque ya había commiteado cada función terminada; cada sesión siguiente retomó desde el traspaso y tomó exactamente una función. La corrida débil, en cambio, metió las 4 funciones juntas en una sola sesión. Con este modelo eso salió rápido y barato (US$0,78 contra US$1,27), pero si esa sesión se hubiera cortado antes de commitear, se perdía todo.

El hallazgo más importante es otro: **las dos corridas marcaron las 4 funciones como `pass` con la interfaz desconectada.** El puente entre la ventana y la app no carga (un problema que en P01 y P02 los agentes sí encontraron y resolvieron) y ningún harness lo detectó, porque la evidencia que pedían era el typecheck, el build, tests de servicios o "la app abre". La política de "no marcar `pass` sin evidencia" se cumplió en la forma, no en el fondo: **la evidencia era del tipo equivocado.** Es exactamente el tema de las clases 09 y 10: cantar victoria antes de tiempo y por qué solo una prueba de punta a punta verifica de verdad. La mejora concreta para el próximo harness es una verificación que use la app como un usuario (por ejemplo, `check-bridge.mjs` dentro de `init.sh`, o un smoke test como el que escribió la corrida fuerte del P01). Una sola corrida por condición: números indicativos.
