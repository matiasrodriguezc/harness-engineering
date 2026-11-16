# P07 · Loops: objetivo, timer y maker-checker

Pregunta del proyecto: ¿qué pasa cuando el agente corre solo, en un loop, sin nadie que lo guíe entre vuelta y vuelta?

**Base:** el repo final de mi harness del P06 (app con calificación, reset e historial; 22 tests; `init.sh` que abre la app).

**Diferencia con el curso:** el curso propone `/goal` y `/loop` dentro de Claude Code de forma interactiva. Acá los loops son scripts externos (`scripts/p07-*.sh`) que lanzan sesiones nuevas de `claude -p` y deciden cuándo parar con chequeos deterministas. Así cada vuelta queda medida y con transcript.

## Experimento 1 · Loop de objetivo (`p07-goal.sh`)

**Objetivo (`prompts/goal.md`), verificado por `prompts/check-goal.sh`:** tests en verde, cobertura de `src/services/` ≥ 95% de líneas y de funciones en total, y cada archivo ≥ 90% de líneas; tipos y arquitectura en verde. Punto de partida: 83,13% de líneas, 74,07% de funciones, cuatro archivos por debajo de 90%.

| | Una sola pasada | Loop de objetivo |
|---|---|---|
| Sesiones | 1 | 4 vueltas (3 con agente; la 2 falló por infraestructura) |
| Costo | US$0,70 | US$0,74 (0,22 + 0 + 0,27 + 0,25) |
| Tiempo de agente | 2:23 | 2:41 |
| Cobertura final (líneas / funciones) | **100% / 100%** | 99,01% / cumple |
| Tests al final | 75 | 45 |
| Resultado | `GOAL: PASS` | `GOAL: PASS` en la vuelta 4 |
| Progreso por vuelta | — | 83,13 → 89,8 → 89,8 (falla) → 96,47 → 99,01 |

**Lo que pasó en el camino (y está documentado en la evidencia):**
- El primer objetivo (≥ 80% de líneas) **ya se cumplía** con los tests del P06: el loop no tenía nada que hacer. Paré la corrida y subí la vara a 95/95/90.
- La vuelta 2 no corrió: `claude: command not found` (Claude Code se actualizó en ese momento). El loop lo contó como una vuelta sin progreso y siguió; no se rompió nada.
- Mi chequeo marcó la pasada única como fallida: la herramienta de cobertura estaba instalada con `--no-save` y el `npm install` de `init.sh` la borró. Reinstalada, el resultado del agente se confirmó: 100/100. El script quedó corregido (`--save-dev`).

## Experimento 2 · Loop con timer (`p07-timer.sh`)

Cada tick corre `init.sh` (determinista y gratis); solo si falla se despierta al agente con la salida del error. En los ticks 2 y 4 el propio script inyecta una falla con un commit de "compañero". 5 ticks cada 4 minutos (unos 22 minutos; el curso sugiere 2 horas, se acortó para que entrara en la sesión).

| Tick | Falla inyectada | `init.sh` | Agente | Después | Costo |
|---|---|---|---|---|---|
| 1 | — | ✅ | No | — | US$0 |
| 2 | Error de tipos en `qa-service.ts` | ❌ | Sí: `git revert` del commit roto | ✅ | US$0,12 |
| 3 | — | ✅ | No | — | US$0 |
| 4 | Import de `fs` en el renderer (viola la arquitectura) | ❌ | Sí: `git revert` del commit roto | ✅ | US$0,11 |
| 5 | — | ✅ | No | — | US$0 |

**Resumen:** 2 fallas inyectadas, 2 detectadas, 2 arregladas, 0 falsos positivos, 0 escalamientos (`ALERT.md` no hizo falta). Para ver si "arreglar" rompió otra cosa corrí la suite oculta del P06 sobre el repo final: **12/12**. Costo total del monitoreo: **US$0,23**, porque en los ticks sanos no se llama al agente.

## Experimento 3 · Maker-checker (`p07-maker-checker.sh`)

Función nueva: búsqueda de documentos (`documents.search(query)` y un campo "Search documents" que filtra la lista). El maker implementa; el checker, independiente y sin tocar código, la prueba en la app real y escribe `checker-verdict.md`. Para con 2 PASS seguidos o 6 vueltas.

| Vuelta | Maker | Checker | Defectos bloqueantes | Costo |
|---|---|---|---|---|
| 1 | Implementó, 38 tests en verde | PASS | 0 (3 observaciones no bloqueantes: recorta espacios de la búsqueda, el contador muestra el total, la lista no se refresca sola al importar por la API) | US$1,06 + US$0,50 |
| 2 | No (confirmación) | PASS | 0 | US$0,58 |

**Verificación independiente** (`scripts/p07-search-accept.mjs`, oculta para los agentes): **7/7**, incluido que preguntar siga funcionando. En la primera corrida mi script dio 6/7 porque preguntaba sin indexar antes; el error era mío y quedó corregido.

## Fallas por capa

| Experimento | Falla | Capa |
|---|---|---|
| Objetivo | La meta inicial ya se cumplía: el loop arrancaba terminado | Tarea (objetivo mal calibrado contra el estado real) |
| Objetivo | Herramienta de cobertura borrada por `npm install` | Entorno (mi setup) |
| Objetivo | Vuelta 2 sin agente (`claude: command not found`) | Entorno (infraestructura) |
| Maker-checker | Mi verificación preguntaba sin indexar | Verificación (mi script) |

## Conclusión

**Los loops funcionaron, pero con este modelo la tarea cabía en una sola pasada.** El loop de objetivo llegó a la meta en 4 vueltas con el mismo costo que una pasada única, que además llegó más lejos (100% y 75 tests). Su valor real estuvo en otro lado: una condición de parada que no depende de lo que diga el agente, y la resistencia a una vuelta que falló por infraestructura sin romper nada. **El loop con timer fue el más claro:** chequeo determinista primero y agente solo cuando hace falta; detectó y revirtió las dos fallas por US$0,23 y no empeoró nada. El maker-checker aprobó en la primera vuelta, y una verificación mía, independiente, confirmó que tenía razón.

Lo que más enseñó el P07 son sus tropiezos, y todos fueron del harness, no del agente: un objetivo que ya estaba cumplido, una herramienta que el propio `init.sh` borraba y un chequeo mío mal escrito. Es la clase 13 en la práctica: **el loop es tan bueno como su condición de parada y sus verificaciones**, y esas hay que verificarlas también.
