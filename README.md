# Harness Engineering · Portfolio

Mi trabajo sobre el curso [Learn Harness Engineering](https://github.com/walkinglabs/learn-harness-engineering) (WalkingLabs, licencia MIT): cómo el entorno alrededor de un agente de IA (instrucciones, herramientas, entorno, estado y verificación) cambia lo que logra el mismo modelo.

## Estructura

| Carpeta | Qué hay |
|---|---|
| `p01/` … `p05/` | Corridas con harness débil y con harness fuerte, con sus métricas |
| `p06/` | Harness completo, benchmark y ablación |
| `p07/` | Loops automatizados |
| `p08/` | El flujo como grafo |

Cada proyecto tiene un `metricas.md` con los resultados y, en `baseline/` e `improved/`, la evidencia de cada corrida (transcript, diff, resumen final del agente).

`scripts/run-session.sh` corre una sesión no interactiva de Claude Code y guarda la evidencia; `scripts/analyze-transcript.py` resume un transcript (turnos, costo, acciones antes de la primera edición).

## Evolución del resultado

_Se completa a medida que avanzan los proyectos._

| Proyecto | Pieza de harness agregada | Corrida débil | Corrida fuerte |
|---|---|---|---|
| P01 | `AGENTS.md`, `init.sh`, `feature_list.json` | 4/4 funciones · 11:40 · 54 turnos · US$3,28 · sin estado para la próxima sesión · alcance decidido por el agente | 4/4 funciones · 9:13 · 31 turnos · US$2,30 · test de punta a punta · estado registrado con evidencia |
| P02 | `session-handoff.md` + `AGENTS.md` con reglas de inicio y de cierre (dos sesiones) | 2/3 funciones · 8:49 · US$1,85 · la sesión 2 dejó lo que aprendió solo en el chat | 3/3 funciones · 7:52 · US$2,04 · la sesión 2 retomó desde el traspaso y lo actualizó · sin tests |
