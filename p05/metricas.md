# P05 · Separar al que hace del que revisa

Pregunta del proyecto: ¿cuánto mejora el resultado al separar roles? Tres configuraciones sobre la misma función, con la misma rúbrica.

**Función (igual en las tres):** "Add multi-turn Q&A conversation history to this knowledge base app: the question panel should show the previous questions and answers as a conversation, with each answer's citations."

**Rúbrica común:** `rubric-template.md`, 8 criterios de 1 a 5. Exige evidencia de haber usado la app; un criterio no verificado no puede pasar de 2.

**Configuraciones** (cada sesión es nueva y solo sabe lo que hay en los archivos; script `scripts/run-p05.sh`):

| | Sesiones |
|---|---|
| **A · un solo rol** | 1: planifica, implementa y se autoevalúa con la rúbrica |
| **B · generador + evaluador** | generador → evaluador escéptico (prueba la app, no toca código) → generador corrige → evaluador reevalúa |
| **C · planificador + generador + evaluador** | planificador escribe `sprint-contract.md` sin tocar código → generador → evaluador → corrección → reevaluación |

**Juez final:** para no depender de la nota de cada configuración (su evaluador es parte del tratamiento), **el mismo juez independiente** (mismo prompt, ignora las evaluaciones previas, prueba la app) calificó las tres. Además verifiqué yo: typecheck, guarda de arquitectura, tests, build y el puente de la interfaz con `scripts/check-bridge.mjs`.

## Resultados

| | A · un rol | B · gen + eval | C · plan + gen + eval |
|---|---|---|---|
| Sesiones | 1 | 4 | 5 |
| Duración | 10 min | 23 min | 33 min |
| Costo (sin el juez) | US$2,54 | US$7,05 | US$8,60 |
| Nota propia | 4,0 (autoevaluación) | 3,9 → **4,5** (evaluador, ronda 1 → 2) | 4,3 → **4,5** (evaluador, ronda 1 → 2) |
| **Nota del juez independiente** | **3,9** | **4,5** | **4,0** |
| Defectos que encontró el evaluador | — | 6 reales (sobre 13 pruebas) | 8 (corrigió 1–6 y 8) |
| Tests | 13 | 20 | 9 |
| Puente de la interfaz (mi verificación) | ✅ | ✅ | ✅ |
| typecheck / guarda / build | ✅ / ✅ / ✅ | ✅ / ✅ / ✅ | ✅ / ✅ / ✅ |
| Tamaño del cambio de código (sin lock, capturas ni archivos de evaluación) | 24 archivos, +1.372 | 26 archivos, +1.895 | 68 archivos, +4.688 |

**Nota del juez por criterio:**

| Criterio | A | B | C |
|---|---|---|---|
| Completitud funcional | 4 | 5 | 5 |
| Diseño visual | 4 | 4 | 4 |
| Marcas de tiempo | 5 | 5 | 4 |
| Citas | 4 | 4 | 4 |
| Interactividad | 3 | 5 | 3 |
| Casos borde | 3 | 4 | 4 |
| Accesibilidad | 4 | 4 | 4 |
| Calidad de código | 4 | 5 | 4 |

**Comparación con el solution del curso:** las rúbricas del curso dicen 1,6 / 3,3 / 4,9 para A / B / C. Son números ilustrativos del propio repo; acá, medidos con un juez independiente, salieron 3,9 / 4,5 / 4,0.

## Fallas por capa

| Config | Falla | Capa |
|---|---|---|
| C | El evaluador de C le puso 4,5 y el juez 4,0: el primer defecto del juez ("las preguntas de seguimiento no reciben la conversación como contexto") el evaluador de C no lo marcó | Verificación (el contrato del planificador fijó criterios y el evaluador los chequeó; lo que quedó fuera del contrato no se miró) |
| C | El cambio más grande de las tres (68 archivos) sin mejor nota | Tarea / alcance (el contrato amplió el trabajo) |
| A | Interactividad y casos borde más flojos (3 y 3) | Verificación (sin una mirada externa, quedaron huecos que B sí corrigió) |

## Conclusión

**Separar al que revisa sirvió; agregar un planificador, no.** Con un modelo actual, un solo agente ya hace un trabajo bueno y se autoevalúa con bastante precisión (se puso 4,0 y el juez 3,9): no apareció la "indulgencia" fuerte que anticipa el curso. Sumar un evaluador independiente que usa la app subió la nota del juez de 3,9 a 4,5: encontró 6 defectos reales y la corrección los cerró, sobre todo en interactividad y casos borde. Sumar además un planificador **no** mejoró: el juez le dio 4,0, por debajo de B, con el cambio de código más grande y el costo más alto. El contrato hizo que el evaluador de C revisara contra criterios fijados de antemano y se le escapó un defecto que el juez marcó primero.

Costo: B cuesta 2,8 veces lo que A por +0,6 puntos; C cuesta 3,4 veces por +0,1. Coincide con la idea de Anthropic de que el evaluador vale la pena cuando la tarea está más allá de lo que el modelo hace bien solo; acá la función era mediana y A ya rozaba el 4. Una sola corrida por configuración y un solo juez: los números son indicativos.
