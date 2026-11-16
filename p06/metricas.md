# P06 · Harness completo, benchmark y ablación

El proyecto final: armar el mejor harness con lo aprendido en P01–P05, medirlo contra un harness débil y quitarle un componente por vez para ver cuáles importan.

## La tarea fija (igual en las cinco corridas)

Tres funciones sobre la app del P06, con nombres de API y `aria-label` fijados para poder verificarlas:

1. **Calificar respuestas:** cada respuesta de `qa.ask` tiene `id`; `feedback.submit(answerId, 'up'|'down')` y `feedback.list()`; persiste tras reiniciar; botones "Mark answer helpful" / "Mark answer not helpful".
2. **Resetear todo:** `app.reset()` borra documentos, fragmentos, historial y calificaciones; el estado vacío persiste; botón "Reset all data" con confirmación.
3. **Historial de conversación:** el panel muestra todo el historial con citas expandibles e indicador de confianza.

"The features must work in the running app."

## La verificación: una suite de aceptación propia, oculta para los agentes

`scripts/p06-acceptance.mjs` abre la app real con una carpeta de datos temporal y, a través del puente del preload, hace 12 chequeos: puente, importar, preguntar con citas, id, calificar, historial, botones en la interfaz, persistencia tras reiniciar (dos reinicios), reset y que el reset persista. No depende de lo que el agente diga que hizo.

Validación de la suite: el starter sin tocar saca **0/12** (el puente no carga). El solution del curso también falla el chequeo 1 por el mismo bug del preload (`require("../shared/types")` con el sandbox activo); con el sandbox desactivado a mano pasa los chequeos que no dependen de los nombres de API de esta tarea.

## Mi harness (`harness-mio/`)

| Componente | Lección de origen |
|---|---|
| `AGENTS.md` corto con rutina de entrada y salida, una función a la vez, commit por función | Clases 03–05 y 07; P02, P03 |
| Definición de terminado en 3 capas: estático → tests + puente → punta a punta en la app real | Clases 09–10; P03 (falsos `pass`) |
| `feature_list.json` con comportamiento + comando de verificación + estado | Clase 08 (a las listas del curso les faltaba el comando) |
| `init.sh`: entorno (`NODE_OPTIONS`), tipos, build, guarda y **la app real** con `smoke-bridge.sh` | Clase 06; P01–P04 |
| `check-architecture.sh` con regla nueva del preload y mensaje qué/por qué/cómo | Clase 10; el bug que apareció en todos los proyectos |
| Traspaso, log de progreso y checklist de cierre | P02, P03 |

Antes de usarlo, sus herramientas se probaron contra el starter: la regla del preload y el chequeo del puente detectan el bug.

## Resultados

| | Débil (starter) | **Mío** | Sin punta a punta | Sin lista de funciones | Sin instrucciones |
|---|---|---|---|---|---|
| **Suite de aceptación** | **12/12** | **12/12** | **12/12** | **12/12** | **12/12** |
| Costo | **US$1,19** | US$2,74 (+US$0,47 limpieza) | US$2,86 | US$2,27 | US$1,51 |
| Duración | 4:36 | 8:56 (+1:25) | 11:03 | 9:01 | 8:29 |
| Turnos | 21 | 41 (+13) | 53 | 38 | 31 |
| Tests automatizados | **0** | 22 | 22 | 18 | 7 |
| Cómo arregló el puente | **Desactivó el sandbox** de Electron | Empaquetó el preload | Empaquetó el preload | Empaquetó el preload | Empaquetó el preload |
| Commits del agente | 0 | 6 (uno por función + base + limpieza) | 6 | 5 | **0** |
| Estado para la próxima sesión | Ninguno | Lista con evidencia, traspaso, log | Lista con evidencia, traspaso, log | Traspaso y log | Lista, traspaso y log |
| `npm run check` | ✅ | ✅ | ✅ | ✅ | ✅ |
| Tamaño del cambio (sin lock) | 16 archivos, +702 | 39 archivos, +1.469 | 35 archivos, +1.392 | 32 archivos, +1.320 | 24 archivos, +942 |

**Limpieza y re-corrida (solo "mío"):** la suite dio 12/12 antes y después de la pasada de limpieza; la limpieza agregó `.gitignore`, marcó en la doc los scripts que no existen y volvió a verificar las funciones (US$0,47).

## Ablación: qué aporta cada componente

| Se quitó | Efecto medido |
|---|---|
| **Verificación de punta a punta** (`smoke-bridge.sh`, regla del preload, capa 3) | Ninguno visible: mismo resultado, mismos tests, sandbox intacto. La tarea ya decía "must work in the running app" y el agente escribió su propia prueba contra la app. |
| **Lista de funciones** | Leve: 18 tests en vez de 22, 5 commits en vez de 6; el estado quedó en traspaso y log. |
| **Instrucciones** (`AGENTS.md` y `CLAUDE.md` propios) | El mayor: **0 commits** y **7 tests** en vez de 22. Aun así encontró y usó `init.sh`, la lista y el traspaso porque estaban en el repo, y empaquetó el preload. |
| **Todo** (harness débil) | Misma suite, menos de la mitad del costo, pero **sin tests, sin commits, sin estado** y con el **sandbox desactivado**. |

## Fallas por capa

| Corrida | Falla | Capa |
|---|---|---|
| Débil | Desactivó el sandbox de Electron para que cargue el preload: la app funciona, pero con una regresión de seguridad que ningún chequeo de comportamiento detecta | Verificación (no hay regla ejecutable de seguridad) |
| Mío | "No desactives el sandbox" está solo como instrucción en el `AGENTS.md`: la regla del preload exime `sandbox: false`, así que una corrida que lo desactive pasa la guarda | Verificación (regla que debería ser ejecutable) |
| Sin instrucciones | No commiteó nada | Instrucciones |
| Suite de aceptación | Con una tarea tan especificada no discriminó: 12/12 en todas | Diseño del experimento |

## Conclusión

**Con una tarea bien especificada, el modelo entregó software que funciona con cualquier harness**: la suite de aceptación dio 12/12 en las cinco variantes, y el harness débil fue el más barato (US$1,19 contra US$2,74 del mío). La especificación de la tarea (nombres de API, `aria-label` y "tiene que funcionar en la app real") hizo buena parte del trabajo que en P03 no hizo nadie. Es la capa 1 de la clase 01.

El harness no cambió **si funciona**, sino **en qué estado queda el repo**: con mi harness hubo 22 tests, un commit por función, la lista de funciones con evidencia, el traspaso para la próxima sesión y el sandbox intacto; con el débil, cero tests, cero commits, nada de estado y el sandbox desactivado. La ablación dice que **lo que más pesa hoy son las instrucciones** (sin ellas: 0 commits y un tercio de los tests), mientras que la verificación de punta a punta no aportó nada medible **en esta tarea**, porque el propio prompt ya la exigía. Y deja una mejora concreta: convertir "no desactives el sandbox" en una regla ejecutable. Una sola corrida por variante: los números son indicativos.
