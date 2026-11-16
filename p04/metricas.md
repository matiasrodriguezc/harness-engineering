# P04 · Feedback de runtime para corregir al agente

Pregunta del proyecto: ¿los logs estructurados y un control de arquitectura hacen que el agente encuentre la causa de un bug más rápido y lo arregle tocando menos?

**El bug sembrado:** en `src/services/indexing-service.ts`, los documentos de más de 1.000 caracteres generan fragmentos vacíos (`content.length > 1000 ? '' : buffer.trim()`). Las tres muestras pasan de 1.000 caracteres, así que las respuestas salen con citas vacías.

**Ajuste al starter del curso:** el starter trae el bug **anotado con un comentario** (`// BUG: For long documents...`). Se borraron esas dos líneas de comentario en las dos corridas, dejando solo el código, para que el agente tenga que encontrarlo.

**Prompt (igual en las dos corridas), en forma de reporte de usuario:** "Users report that when they ask questions about their imported documents, the answers come back with empty citation excerpts and no useful content. Find the root cause and fix it."

**Modelo y forma de correr:** Claude Opus 5.5, modo no interactivo, `--permission-mode auto`, sin skills ni MCPs, una sola sesión sin tope.

**Qué cambia entre corridas:**

| | Corrida 1 · harness débil | Corrida 2 · harness fuerte |
|---|---|---|
| `AGENTS.md` | Starter: 5 líneas (comandos y dos reglas) | Solution: rutina de inicio, observabilidad, restricciones de capas, Definition of Done y rutina de cierre |
| Logs de indexación | `console.log` con largo del contenido y cantidad de fragmentos | Logger estructurado (JSON) que además informa **el total de caracteres de los fragmentos** |
| `docs/ARCHITECTURE.md` | No | Sí |
| `scripts/check-architecture.sh` | No | Sí |
| `clean-state-checklist.md` | No | Sí, sin marcar; incluye "no empty chunks in indexed documents" (una pista hacia el bug que es parte del harness del curso) |

## Resultados

| Métrica | Corrida 1 | Corrida 2 |
|---|---|---|
| Duración | 59 s | 92 s |
| Turnos | 7 | 15 |
| Costo | US$0,29 | US$0,49 |
| Acciones hasta ver la línea del bug | **2** (leyó el código de indexación) | **8** (antes cumplió la rutina de inicio y arregló el typecheck roto) |
| ¿Usó los logs de runtime para encontrarlo? | No (no hacía falta) | No: lo encontró leyendo el código, igual que la débil |
| ¿Encontró la causa raíz correcta? | Sí | Sí |
| Arreglo del bug | `indexing-service.ts` (+16 líneas): devuelve el texto y además **reconstruye índices ya rotos** | `indexing-service.ts` (6 líneas): devuelve el texto; los índices ya rotos quedan como "no arreglado", documentado |
| Otros cambios | Ninguno | Commit aparte que arregla los 14 errores de typecheck del starter (5 archivos del renderer), como pide el `AGENTS.md` |
| ¿Verificó con datos reales? | Sí, tests con los documentos de muestra; no abrió la app | Sí, test con los documentos de muestra; no abrió la app |
| Test de regresión | 3 tests (fallan sin el arreglo) | 2 tests (fallan sin el arreglo) |
| `npm test` encuentra los tests | No (lo avisó y ofreció arreglarlo) | Sí (agregó `vitest.config.ts`) |
| `npm run check` al final | 14 errores (los mismos del starter, fuera de alcance) | 0 errores |
| `check-architecture.sh` al final | Pasa (lo corrí yo; la corrida no tenía el script) | Pasa |
| Commits | 1 (el del script de fin de sesión) | 2 del agente: typecheck por un lado, bug por el otro |
| Tamaño del cambio (sin `package-lock.json`) | 2 archivos, +73 / −5 | 9 archivos, +82 / −16 |
| Mi verificación | Condición del bug eliminada, 3/3 tests, guarda OK | Condición del bug eliminada, 0 errores de tipos, 2/2 tests con `npm test`, guarda y build OK |

## Fallas por capa

| Corrida | Falla | Capa |
|---|---|---|
| 1 | Dejó el repo con el typecheck en rojo (14 errores previos) y `npm test` sin encontrar tests: arregló el bug pero no el punto de partida | Entorno / verificación (sin regla de "arreglá primero lo que está roto") |
| 2 | No reconstruyó los índices que el bug ya había roto: el usuario tiene que reindexar a mano | Tarea (el reporte pide "arreglar"; no hay criterio de qué cuenta como arreglado para datos existentes) |
| 1 y 2 | Ninguna abrió la app para confirmar que las respuestas se ven bien | Verificación (igual que en P03) |
| Diseño del experimento | El bug se ve leyendo el código: los logs de runtime no tuvieron oportunidad de aportar | — |

## Conclusión

La hipótesis del P04 era que los logs estructurados ayudan a encontrar la causa más rápido. **Este experimento no pudo probarla:** el bug era visible leyendo el código (una condición `content.length > 1000` en el chunking), y las dos corridas lo encontraron así, sin mirar logs. La débil incluso llegó antes (2 acciones contra 8). Para medir el aporte real de las señales de runtime hace falta un bug que solo aparezca al ejecutar: dependiente de los datos, de la configuración o de un estado que el código no muestra.

Lo que sí cambió el harness fue **la disciplina**: la corrida fuerte cumplió la rutina de inicio, detectó que el typecheck ya estaba roto y lo arregló primero en un commit aparte, dejó `npm test` funcionando y terminó con todo en verde (typecheck, tests, guarda de arquitectura, build). La débil arregló solo el bug y dejó el repo con 14 errores de tipos y sin forma de correr los tests con el comando estándar. Esa disciplina costó un 70% más (US$0,49 contra US$0,29). Y la débil hizo algo que la fuerte no: reconstruir los índices que el bug ya había dañado, un arreglo más completo para el usuario. Una sola corrida por condición: números indicativos.
