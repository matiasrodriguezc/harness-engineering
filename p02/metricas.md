# P02 · Repo legible y retomable

Pregunta del proyecto: ¿una sesión nueva puede retomar el trabajo leyendo solo el repo, sin que nadie le explique nada?

**Funciones a implementar:** importación de documentos, vista de detalle con contenido (y borrar) y persistencia entre reinicios. Se reparten en dos sesiones.

**Modelo y forma de correr:** igual que en P01 (Claude Opus 5.5, modo no interactivo, `--permission-mode auto`, sin skills ni MCPs). Script: `scripts/run-session.sh`. Cada sesión es nueva: no hereda nada salvo lo que quedó en los archivos.

**Prompts (iguales en las dos corridas):**
- Sesión 1: "Implement document import for this knowledge base app. This session covers import only; the document detail view and persistence will be done in a later session."
- Sesión 2: "Continue working on this project."

**Qué cambia entre corridas:**

| | Corrida 1 · harness débil | Corrida 2 · harness fuerte |
|---|---|---|
| `AGENTS.md` | Starter: 20 líneas (comandos, capas, convenciones) | Solution: reglas de inicio, Definition of Done y "al cerrar, actualizá `session-handoff.md`" |
| `docs/` | `ARCHITECTURE.md` y `PRODUCT.md` del starter | Las del solution (cambian poco respecto del starter) |
| `feature_list.json` | Sí (3 funciones `not-started`) | Sí (3 funciones `not-started`) |
| `session-handoff.md` | No existe | Plantilla en blanco del curso |

**Diferencia con el curso:** el doc del P02 no trae protocolo ni métricas; este diseño (dos sesiones con prompts fijos, la segunda deliberadamente vaga) es propio.

## Resultados por sesión

| Métrica | C1 · sesión 1 | C1 · sesión 2 | C2 · sesión 1 | C2 · sesión 2 |
|---|---|---|---|---|
| Duración | 6:27 | 2:22 | 5:05 | 2:47 |
| Turnos | 24 | 12 | 28 | 15 |
| Costo | US$1,18 | US$0,67 | US$1,25 | US$0,79 |
| Acciones antes de la primera edición (redescubrimiento) | 5 | 3 | 5 | 3 |
| ¿Respetó el alcance de la sesión 1? | Sí (solo importación) | — | Sí (solo importación) | — |
| ¿Dejó registro para la próxima sesión? | `feature_list.json` y una sección de `ARCHITECTURE.md` | `feature_list.json`; los problemas que encontró quedaron **solo en su mensaje final**, no en el repo | `session-handoff.md` completo: verificado, roto, próximo paso, qué no tocar | Actualizó `session-handoff.md` con los problemas pendientes y el próximo trabajo |
| ¿La sesión 2 identificó bien qué faltaba? | — | Sí, pero hizo **una sola** de las dos funciones pendientes | — | Sí, y terminó **las dos** |
| ¿La sesión 2 rompió o rehízo trabajo de la 1? | — | No | — | No (respetó la lista de "qué no tocar" del traspaso) |
| **Total de la corrida** | | **8:49 · 36 turnos · US$1,85** | | **7:52 · 43 turnos · US$2,04** |

## Resultado final de cada corrida

| Función | Corrida 1 | Corrida 2 |
|---|---|---|
| Importación de documentos | ✅ | ✅ |
| Detalle con contenido y borrar | ✅ | ✅ |
| Persistencia entre reinicios | ❌ los datos se guardan, pero la lista aparece vacía al reiniciar (no se cargan al iniciar) | ✅ carga al iniciar; el agente lo probó cerrando y reabriendo la app |
| `npm run check` / build | ✅ / ✅ | ✅ / ✅ |
| Tests | 19/19 (los escribió el agente) | No escribió tests; verificó manejando la app real por Chrome DevTools |
| La app abre | Solo con `env -u NODE_OPTIONS` (no lo avisó) | Solo con `env -u NODE_OPTIONS` (lo dejó documentado en el traspaso) |
| Tamaño del cambio total (sin `package-lock.json`) | 22 archivos, +720 / −175 | 19 archivos, +427 / −125 |

## Fallas por capa

| Corrida | Falla | Capa |
|---|---|---|
| 1 | La sesión 2 encontró dos bugs (la lista no carga al iniciar, el botón de indexar un documento no actualiza el índice) y los dejó solo en su respuesta final: una sesión 3 tendría que redescubrirlos | Estado |
| 1 | Terminó con la persistencia sin hacer: la sesión 2 hizo una función y paró | Estado / tarea (sin un "próximo paso" ni un criterio de "terminado" para el conjunto) |
| 1 | `npm run dev` no abre por `NODE_OPTIONS` y no lo avisó | Entorno |
| 2 | No escribió tests automatizados; la verificación quedó en manejo manual de la app | Verificación (la Definition of Done del `AGENTS.md` no pide tests) |
| 2 | `npm run dev` no abre por `NODE_OPTIONS`; lo documentó pero no lo arregló | Entorno |

## Conclusión

El costo de redescubrimiento fue **igual** en las dos corridas: la sesión 2 tardó 3 acciones en ubicarse en ambos casos, porque el starter "débil" ya trae `feature_list.json` y eso alcanza para saber qué falta. Lo que cambió fue **qué hizo la sesión 2 con esa información**. Sin traspaso, completó una función, encontró dos bugs y los dejó solo en su mensaje final, fuera del repo: el trabajo quedó en 2 de 3 y lo que aprendió se pierde para la sesión siguiente. Con traspaso, leyó primero `session-handoff.md` (qué está verificado, qué está roto, el próximo paso y qué cuenta como terminado), terminó las dos funciones pendientes, probó la persistencia reiniciando la app y volvió a dejar escrito lo pendiente. Costó apenas más (US$2,04 contra US$1,85) por hacer el doble de trabajo en la segunda sesión.

Es la idea de las clases 03 y 04 en la práctica: el conocimiento que queda en el chat no existe para la próxima sesión. Y aparece un costo nuevo: la Definition of Done del harness fuerte no pide tests, y esta corrida no escribió ninguno, mientras que la débil escribió 19. La mejora para el próximo harness es agregar "tests automatizados para cada función" a la definición de terminado. Como en P01, es una sola corrida por condición: los números son indicativos.

