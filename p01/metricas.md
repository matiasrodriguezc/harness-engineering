# P01 · Solo prompt contra harness mínimo

Misma tarea, mismo agente, mismo modelo. Lo único que cambia es el harness.

**Tarea (igual en las dos corridas):** "Build an Electron app that can show documents and answer questions."

**Cómo se lanzó el agente:** modo no interactivo, `claude -p "<tarea>" --disable-slash-commands --strict-mcp-config --permission-mode auto --output-format stream-json --verbose`. Sin skills ni MCPs para que no se cuele otro harness. En modo no interactivo nadie le contesta preguntas, así que las intervenciones humanas son 0 por diseño en las dos corridas.

**Modelo:** Claude Opus 5.5 (`claude-opus-5-5`), Claude Code 2.1.278.

**Diferencia con el protocolo del curso:** el curso asume una corrida interactiva; acá se usó modo no interactivo para medir igual las dos corridas y guardar el transcript completo.

## Resultados

| Métrica | Corrida 1 · harness débil | Corrida 2 · harness fuerte |
|---|---|---|
| Hora de inicio | 20:16:14 | 20:29:49 |
| Hora en que el agente dijo "listo" | 20:27:54 (11 min 40 s) | 20:39:02 (9 min 13 s) |
| Turnos del agente | 54 | 31 |
| Costo | US$3,28 | US$2,30 |
| Resultado (completo / parcial / fallido) | Completo (4 de 4), y fue mucho más allá de lo pedido | Completo (4 de 4) + 8 funciones extra, todas registradas en `feature_list.json` con evidencia |
| Primer arranque exitoso (minutos desde el inicio) | ~12 (apenas terminó), pero solo quitando `NODE_OPTIONS` del entorno | ~9 (apenas terminó), con `npm run dev` a secas: arregló el script de arranque |
| Intervenciones humanas | 0 (modo no interactivo) | 0 (modo no interactivo) |
| ¿Cantó victoria con la app sin arrancar? (sí / no) | No: avisó que con mi `NODE_OPTIONS` Electron no arranca y dio el comando | No: lo verificó con un test de punta a punta sobre la app real |
| Verificación independiente (mía) | `npm run check` limpio, 34/34 tests, build OK, la app abre | `init.sh` OK, 17/17 tests, smoke test de punta a punta PASS, la app abre |
| Tamaño del cambio (sin `package-lock.json`) | 25 archivos, +1.917 / −788 líneas | 26 archivos, +1.524 / −590 líneas |
| Dejó estado para la próxima sesión | No (solo un README) | Sí: `feature_list.json` con evidencia y `claude-progress.md` con el log |
| `init.sh` al final (solo corrida 2) | — | ✅ pasa |

## Las 4 funciones esperadas

Marcá ✅ si funciona al probarla vos, ⚠️ si está a medias, ❌ si no está.

| Función | Corrida 1 | Corrida 2 |
|---|---|---|
| Se abre la ventana de la app | ✅ (con `env -u NODE_OPTIONS`) | ✅ (`npm run dev` a secas) |
| Lista de documentos a la izquierda | ✅ (layout verificado en el código; sin captura de pantalla) | ✅ (verificado por el smoke test) |
| Panel de preguntas y respuestas a la derecha | ✅ (ídem) | ✅ (ídem) |
| Se crea el directorio local de datos | ✅ `~/Library/Application Support/knowledge-base/knowledge-base-data` | ✅ (mismo directorio) |

## Fallas por capa (clase 01)

Para cada falla que veas, anotá en qué capa cae: tarea, contexto, entorno, verificación o estado.

| Corrida | Falla | Capa |
|---|---|---|
| 1 | `NODE_OPTIONS=--openssl-legacy-provider` en mi shell impide arrancar Electron (el agente lo detectó y lo avisó) | Entorno |
| 1 | Agregó por su cuenta un modo opcional que manda pasajes a la API de Anthropic si hay `ANTHROPIC_API_KEY`; no estaba pedido y no lo probó | Tarea (alcance no definido → el agente se extiende) |
| 1 | Borró y reemplazó tres componentes del starter (`DocumentDetail`, `ImportPanel`, `QuestionPanel`) con un diseño propio | Tarea / contexto (sin especificación ni convenciones escritas, decide solo) |
| 2 | Desactivó el sandbox de Electron (`sandbox: false`) porque el preload importa las constantes de `src/shared/types.ts`, como pide el `AGENTS.md`; la corrida 1 había resuelto lo mismo manteniendo el sandbox. Lo declaró y ofreció revertirlo | Contexto (el harness tiene una convención que choca con el sandbox y no dice qué priorizar) |
| 2 | Cambió las respuestas "mock" que pide `docs/PRODUCT.md` por respuestas extraídas de los documentos. Lo declaró como desvío de la especificación | Tarea (consigna vaga contra especificación escrita) |
| 2 | Sumó 8 funciones más allá de las 4 pedidas | Tarea, pero visible: todas quedaron en `feature_list.json` con evidencia |

## Notas durante la corrida

- **Corrida 1:** con un modelo actual, el harness débil no produjo el fracaso que anticipa el curso. El agente exploró el starter, encontró y corrigió bugs reales (Q&A falso, importación que no hacía nada, preload bloqueado por el sandbox, indexación incompleta), escribió 34 tests y manejó la app con un script. Lo que sí mostró es la otra cara del harness débil: **sin límites escritos, decide el alcance por su cuenta** (rediseñó componentes y sumó una integración con una API externa que nadie pidió).
- **Corrida 2:** siguió el protocolo del `AGENTS.md` (corrió `init.sh`), respetó la estructura de componentes del starter en lugar de reemplazarla, se mantuvo 100% local como dice la especificación, escribió un test de punta a punta sobre la app real y dejó el estado listo para la próxima sesión.

## Conclusión

Con Claude Opus 5.5, las dos corridas terminaron con las 4 funciones andando, así que el harness mínimo **no cambió si el agente termina, sino cómo trabaja**. Con harness, la corrida fue un 21% más rápida (9:13 contra 11:40), usó un 43% menos de turnos (31 contra 54) y costó un 30% menos (US$2,30 contra US$3,28), con un cambio más chico (+1.524 contra +1.917 líneas). Además, la definición de "hecho" del `AGENTS.md` empujó a una verificación más fuerte (un test de punta a punta sobre la app real, frente a tests de servicios y un script), y la corrida 2 dejó `feature_list.json` y `claude-progress.md` con evidencia, de modo que la próxima sesión no arranca de cero. Sin harness, el agente decidió el alcance por su cuenta: rediseñó componentes y sumó una integración con una API externa que nadie pidió.

El harness también mostró un límite: una convención del `AGENTS.md` (constantes de IPC compartidas) chocó con el sandbox de Electron y el agente eligió desactivarlo, algo que la corrida sin harness no hizo. Un harness incompleto también guía, a veces hacia una peor decisión; la mejora es agregar una regla explícita ("mantener `sandbox: true`; si el preload necesita código compartido, empaquetarlo"). Es una sola corrida por condición, así que las diferencias de tiempo y costo son indicativas, no concluyentes.
