@AGENTS.md

## Commands

- `bash init.sh`: full health check (types, build, architecture, real app bridge)
- `npm run check`: type check
- `npm test`: unit and integration tests
- `bash scripts/check-architecture.sh`: layer boundaries, including the preload rule
- `bash scripts/smoke-bridge.sh`: opens the real app and confirms the UI can reach `window.knowledgeBase`
