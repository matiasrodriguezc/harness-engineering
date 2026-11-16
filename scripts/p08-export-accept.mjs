// Independent check of conversation export (P08). The agents do NOT see it.
// Opens the real app (Electron) with a temporary data folder, uses the API through the preload
// bridge (window.knowledgeBase), restarts the app to test persistence and checks the UI.
// Usage: node --experimental-websocket scripts/p08-export-accept.mjs <app-folder> [port]
// Requires the app to be built already (npm run build).
import { spawn } from 'node:child_process';
import { mkdtempSync, readdirSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const APP = resolve(process.argv[2]);
const PORT = process.argv[3] || '9340';
const DATA = mkdtempSync(join(tmpdir(), 'kb-accept-'));
const SAMPLES = join(APP, 'data', 'sample-documents');
const results = [];
const check = (name, ok, detail = '') => { results.push({ name, ok: !!ok, detail }); };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function launch() {
  const env = { ...process.env }; delete env.NODE_OPTIONS;
  const p = spawn('npx', ['electron', '.', `--remote-debugging-port=${PORT}`, `--user-data-dir=${DATA}`],
    { cwd: APP, env, stdio: 'ignore', detached: true });
  return p;
}
async function connect() {
  for (let i = 0; i < 60; i++) {
    try {
      const t = await (await fetch(`http://127.0.0.1:${PORT}/json/list`)).json();
      const page = t.find((x) => x.type === 'page');
      if (page) {
        const ws = new WebSocket(page.webSocketDebuggerUrl);
        await new Promise((r, j) => { ws.addEventListener('open', r); ws.addEventListener('error', j); });
        return ws;
      }
    } catch {}
    await sleep(500);
  }
  throw new Error('the app did not open a window');
}
function evaluator(ws) {
  let n = 0;
  return (expression) => new Promise((resolveP) => {
    const id = ++n;
    const onMsg = (ev) => {
      const m = JSON.parse(ev.data);
      if (m.id === id) {
        ws.removeEventListener('message', onMsg);
        if (m.result?.exceptionDetails) resolveP({ error: m.result.exceptionDetails.exception?.description || 'exception' });
        else resolveP({ value: m.result?.result?.value });
      }
    };
    ws.addEventListener('message', onMsg);
    ws.send(JSON.stringify({ id, method: 'Runtime.evaluate', params: { expression, awaitPromise: true, returnByValue: true } }));
  });
}
async function withApp(fn) {
  const proc = launch();
  let ws;
  try {
    ws = await connect();
    await sleep(1500);
    await fn(evaluator(ws));
  } finally {
    try { ws?.close(); } catch {}
    try { process.kill(-proc.pid, 'SIGTERM'); } catch {}
    await sleep(1500);
  }
}
const kb = (code) => `(async () => { const kb = window.knowledgeBase; ${code} })()`;

const docs = readdirSync(SAMPLES).map((f) => join(SAMPLES, f));
try {
  await withApp(async (ev) => {
    const b = await ev('typeof window.knowledgeBase');
    check('1. The UI has the bridge', b.value === 'object', b.value); if (b.value !== 'object') return;
    const e0 = await ev(kb(`const m = await kb.conversation.export(); return { type: typeof m, len: (m||'').length, txt: (m||'').slice(0,120) };`));
    check('2. export() with an empty conversation returns Markdown', e0.value && e0.value.type === 'string' && e0.value.len > 0, JSON.stringify(e0));
    const e1 = await ev(kb(`for (const p of ${JSON.stringify(docs)}) { await kb.documents.import(p); }
      await kb.indexing.start(); await new Promise(r => setTimeout(r, 1500));
      const q = 'What did the team decide about the vector database?'; const a = await kb.qa.ask(q);
      const m = await kb.conversation.export(); const t = (a.citations && a.citations[0] && a.citations[0].documentTitle) || '';
      return { hasQ: m.includes(q), hasTitle: t ? m.includes(t) : false, hasExcerpt: a.citations && a.citations[0] ? m.includes(a.citations[0].excerpt.slice(0, 30)) : false };`));
    const v = e1.value || {};
    check('3. export() includes the question', v.hasQ === true, JSON.stringify(e1));
    check('4. export() includes the cited document title', v.hasTitle === true, JSON.stringify(e1));
    check('5. export() includes the citation excerpt', v.hasExcerpt === true, JSON.stringify(e1));
    await ev('location.reload()'); await sleep(2500);
    const ui = await ev(`document.querySelectorAll('[aria-label="Export conversation"]').length`);
    check('6. The UI has the "Export conversation" button', ui.value > 0, JSON.stringify(ui));
  });
} catch (e) { check('The app started', false, String(e)); } finally { rmSync(DATA, { recursive: true, force: true }); }
const total = 6; const passed = results.filter((r) => r.ok).length;
console.log(JSON.stringify({ app: APP, passed, total, results }, null, 2));
