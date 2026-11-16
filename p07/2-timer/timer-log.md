# Registro del loop con timer

| Tick | Hora | Falla inyectada | Chequeo | ¿Se despertó al agente? | Chequeo después | Costo del agente |
|---|---|---|---|---|---|---|
| 1 | 00:15:10 | — | ✅ pasa | No | — | US$0 |
| 2 | 00:19:20 | error de tipos en qa-service.ts | ❌ falla | Sí | ✅ pasa | US$0.12 |
| 3 | 00:23:57 | — | ✅ pasa | No | — | US$0 |
| 4 | 00:28:05 | import de fs en el renderer (viola la arquitectura) | ❌ falla | Sí | ✅ pasa | US$0.11 |
| 5 | 00:32:43 | — | ✅ pasa | No | — | US$0 |
