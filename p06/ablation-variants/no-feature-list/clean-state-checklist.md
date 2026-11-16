# Clean state checklist

Run at the end of every session. If an item fails, the work is not done.

- [ ] `bash init.sh` passes (types, build, architecture, real app bridge)
- [ ] `npm test` passes
- [ ] Every feature reported as done has evidence with the commands that ran
- [ ] No temporary scripts, debug output or screenshots left outside a clearly named folder
- [ ] `session-handoff.md` and `claude-progress.md` are updated
- [ ] Everything is committed
- [ ] A new session could continue from the repo alone
