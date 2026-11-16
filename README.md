# Harness Engineering · Portfolio

Ocho experimentos medidos con Claude Code sobre el curso [Learn Harness Engineering](https://github.com/walkinglabs/learn-harness-engineering) (WalkingLabs, licencia MIT): cómo el entorno alrededor de un agente de IA (instrucciones, herramientas, entorno, estado y verificación) cambia lo que entrega el mismo modelo.

**Demo en vivo:** https://harness-engineering-matias.vercel.app (el código de la página es [`index.html`](index.html); Vercel publica solo ese archivo, ver `.vercelignore`).

- **48 sesiones** de agente (Claude Opus 5.5, modo no interactivo), todas con transcript guardado · **US$53,86** en total
- En cada proyecto, la misma tarea con el mismo modelo, cambiando solo el harness
- Cada resultado verificado por fuera del agente: typecheck, tests, build, la app real y verificaciones propias que los agentes no veían

## Hallazgos principales

1. **Con un modelo actual, el harness cambia cómo se trabaja más que si se termina.** En casi todos los proyectos las dos versiones entregaron la tarea; el harness movió el costo, la verificación, los tests, los commits y lo que queda escrito para la próxima sesión.
2. **La evidencia del tipo equivocado produce falsos "terminado".** En P03, dos agentes marcaron 4 funciones como terminadas con la interfaz desconectada. Solo una prueba en la app real lo detecta.
3. **Las soluciones del curso repiten un bug:** el preload importa un archivo local con el sandbox de Electron activo y la interfaz queda sin acceso a la app (también en la solución del proyecto final, calificada 5/5 por su propia rúbrica). Quedó convertido en una regla ejecutable.
4. **Una tarea bien especificada hace buena parte del trabajo.** En P06, con nombres de API fijos y "tiene que funcionar en la app real", las cinco variantes pasaron la suite oculta, incluido el harness débil.
5. **Un evaluador independiente suma; un planificador, no siempre** (P05: juez 3,9 → 4,5 con evaluador; 4,0 con planificador).
6. **En la ablación, lo que más pesa son las instrucciones** (P06: sin `AGENTS.md`, cero commits y un tercio de los tests).

## Resultados por proyecto

| Proyecto | Qué se probó | Corrida débil | Corrida fuerte |
|---|---|---|---|
| [P01](p01/metricas.md) | `AGENTS.md`, `init.sh`, `feature_list.json` | 4/4 funciones · 11:40 · 54 turnos · US$3,28 · sin estado para la próxima sesión · alcance decidido por el agente | 4/4 funciones · 9:13 · 31 turnos · US$2,30 · test de punta a punta · estado registrado con evidencia |
| [P02](p02/metricas.md) | `session-handoff.md` + `AGENTS.md` con reglas de inicio y de cierre (dos sesiones) | 2/3 funciones · 8:49 · US$1,85 · la sesión 2 dejó lo que aprendió solo en el chat | 3/3 funciones · 7:52 · US$2,04 · la sesión 2 retomó desde el traspaso y lo actualizó · sin tests |
| [P03](p03/metricas.md) | Una función a la vez con commit por función, `init.sh`, checklist de cierre (sesiones cortadas por tope de gasto) | 4/4 en `pass` · 2 sesiones · US$0,78 · las 4 funciones juntas · **interfaz desconectada** | 4/4 en `pass` · 3 sesiones · US$1,27 · un commit por función, el corte no perdió nada · **interfaz desconectada** |
| [P04](p04/metricas.md) | Logger estructurado, guarda de arquitectura, rutina de inicio y cierre (bug sembrado) | Bug arreglado en 59 s · US$0,29 · repo queda con 14 errores de tipos | Bug arreglado en 92 s · US$0,49 · arregló primero el typecheck roto, todo en verde · los logs no hicieron falta |
| [P05](p05/metricas.md) | Roles separados: generador + evaluador (B) y además planificador (C), contra un solo rol (A) | A: juez 3,9 · US$2,54 | B: juez **4,5** · US$7,05 · C: juez 4,0 · US$8,60 |
| [P06](p06/metricas.md) | Mi harness completo (3 capas de verificación, lista con comandos, `init.sh` que abre la app, regla del preload) + ablación | Suite oculta 12/12 · US$1,19 · 0 tests · sandbox desactivado · sin estado | Suite oculta 12/12 · US$2,74 · 22 tests · commit por función · estado completo · la ablación muestra que lo que más pesa son las instrucciones |
| [P07](p07/metricas.md) | Loops externos: objetivo con parada determinista, timer con chequeo antes del agente, maker-checker | Una pasada: 100% de cobertura · US$0,70 | Loop de objetivo: 99% en 4 vueltas · US$0,74 · timer: 2/2 fallas revertidas por US$0,23 · maker-checker: PASS en la vuelta 1, confirmado 7/7 |
| [P08](p08/metricas.md) | Grafo explícito: verificación funcional ∥ revisión en worktrees, vuelta atrás según la capa, aprobación humana con timeout | Loop del P07: 4 aristas implícitas encontradas al dibujarlo | Verificación en paralelo 34% más rápida · función 6/6 · regresión 12/12 · detenido esperando aprobación humana |

## Estructura

| Carpeta | Qué hay |
|---|---|
| `p01/` … `p04/` | Corrida con harness débil (`baseline/`) y fuerte (`improved/`): transcript, diff, resumen del agente, harness usado, `metricas.md` |
| `p05/` | Las tres configuraciones de roles, sus evaluaciones y el informe del juez independiente |
| `p06/` | Mi harness (`harness-mio/`), las variantes de la ablación y las corridas con su resultado en la suite de aceptación |
| `p07/` | Los tres loops con sus prompts, el registro del timer y el `loop-state.md` |
| `p08/` | `graph.md` (el loop del P07 como grafo) y el recorrido del grafo ejecutable, con su pedido de aprobación |
| `scripts/` | Todo lo necesario para repetir los experimentos |
| `index.html` | La página de demo |

## Herramientas

| Script | Qué hace |
|---|---|
| `run-session.sh` | Corre una sesión no interactiva de Claude Code en una carpeta aislada y guarda transcript, diff y tiempos |
| `run-multi.sh` | Encadena sesiones nuevas con tope de gasto (simula reinicios) hasta completar `feature_list.json` |
| `analyze-transcript.py` | Turnos, costo y acciones antes de la primera edición (costo de redescubrimiento) |
| `check-bridge.mjs` | Se conecta a la app abierta por Chrome DevTools y verifica que la interfaz tenga acceso a la API |
| `run-p05.sh` | Las tres configuraciones de roles y el juez independiente |
| `run-p06.sh`, `run-p06-all.sh` | Las variantes del P06 con la suite de aceptación al final |
| `p06-acceptance.mjs` | Suite de punta a punta oculta: 12 chequeos con dos reinicios de la app |
| `p07-goal.sh`, `p07-timer.sh`, `p07-maker-checker.sh` | Los tres loops del P07 |
| `p07-search-accept.mjs`, `p08-export-accept.mjs` | Verificaciones independientes de las funciones de P07 y P08 |
| `p08-graph.sh` | El grafo: plan, implement, verificación en paralelo en worktrees, ruteo, aprobación humana y timeout |

## Pendiente: la aprobación humana del P08

El grafo del P08 está detenido en su nodo de aprobación, esperando la decisión de una persona (a propósito, no se simuló). Para completarlo: leer `p08/3-grafo/approval-request.md`, escribir `approval: approved` o `approval: rejected` en `~/harness-runs/p08-graph/state.md` y correr `scripts/p08-graph.sh resume`.

## Límites

- Una corrida por condición: las diferencias de tiempo y costo son indicativas, no estadísticas.
- Un solo modelo (Claude Opus 5.5); con otro, varias conclusiones pueden cambiar.
- Las sesiones corrieron en modo no interactivo, no a mano como propone el curso, para medirlas igual; las intervenciones humanas son cero por diseño.
- Varios protocolos los diseñé yo porque el curso no los define (P02, P03, P05–P08). Cada ajuste y cada tropiezo está documentado en el `metricas.md` del proyecto.
