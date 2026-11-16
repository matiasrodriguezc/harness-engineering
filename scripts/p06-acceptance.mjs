// P06 end-to-end acceptance suite. The agents do NOT see it.
// Opens the real app (Electron) with a temporary data folder, uses the API through the preload
// bridge (window.knowledgeBase), restarts the app to test persistence and checks the UI.
// Usage: node --experimental-websocket scripts/p06-acceptance.mjs <app-folder> [port]
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
let answerId = null;

try {
  // Phase 1: fresh data
  await withApp(async (ev) => {
    const bridge = await ev('typeof window.knowledgeBase');
    check('1. The UI has the bridge (window.knowledgeBase)', bridge.value === 'object', bridge.value);
    if (bridge.value !== 'object') return;
    const imp = await ev(kb(`for (const p of ${JSON.stringify(docs)}) { await kb.documents.import(p); } return (await kb.documents.list()).length;`));
    check('2. Import the 3 sample documents', imp.value >= 3, JSON.stringify(imp));
    const ask = await ev(kb(`await kb.indexing.start(); await new Promise(r => setTimeout(r, 1500));
      const a = await kb.qa.ask('What did the team decide about the vector database?');
      return { id: a && a.id, n: a && a.citations ? a.citations.length : 0, ex: a && a.citations && a.citations[0] ? (a.citations[0].excerpt || '').length : 0 };`));
    const a = ask.value || {};
    check('3. Asking returns an answer with non-empty citations', a.n > 0 && a.ex > 0, JSON.stringify(ask));
    check('4. The answer has an id', typeof a.id === 'string' && a.id.length > 0, String(a.id));
    answerId = a.id;
    const fb = await ev(kb(`await kb.feedback.submit(${JSON.stringify(answerId)}, 'up'); const l = await kb.feedback.list();
      return l.some(f => f.answerId === ${JSON.stringify(answerId)} && f.rating === 'up');`));
    check('5. Rate the answer and see it in feedback.list()', !!answerId && fb.value === true, JSON.stringify(fb));
    const hist = await ev(kb(`return (await kb.qa.history()).length;`));
    check('6. The history has the question', hist.value >= 1, JSON.stringify(hist));
    await ev('location.reload()'); await sleep(2500);
    const ui = await ev(`({ up: document.querySelectorAll('[aria-label="Mark answer helpful"]').length,
      down: document.querySelectorAll('[aria-label="Mark answer not helpful"]').length,
      reset: document.querySelectorAll('[aria-label="Reset all data"]').length })`);
    const u = ui.value || {};
    check('7. The UI shows the rating buttons', u.up > 0 && u.down > 0, JSON.stringify(u));
    check('8. The UI has the "Reset all data" button', u.reset > 0, JSON.stringify(u));
  });
  // Phase 2: restart, persistence and reset
  await withApp(async (ev) => {
    const b = await ev('typeof window.knowledgeBase'); if (b.value !== 'object') return;
    const p = await ev(kb(`const f = await kb.feedback.list(); return { fb: f.some(x => x.answerId === ${JSON.stringify(answerId)}),
      docs: (await kb.documents.list()).length, hist: (await kb.qa.history()).length };`));
    const v = p.value || {};
    check('9. After restarting, the rating persists', !!answerId && v.fb === true, JSON.stringify(p));
    check('10. After restarting, documents and history persist', v.docs >= 3 && v.hist >= 1, JSON.stringify(p));
    const r = await ev(kb(`await kb.app.reset(); return { docs: (await kb.documents.list()).length,
      hist: (await kb.qa.history()).length, fb: (await kb.feedback.list()).length };`));
    const w = r.value || {};
    check('11. Reset leaves documents, history and ratings at zero', w.docs === 0 && w.hist === 0 && w.fb === 0, JSON.stringify(r));
  });
  // Phase 3: the reset persists
  await withApp(async (ev) => {
    const b = await ev('typeof window.knowledgeBase'); if (b.value !== 'object') return;
    const r = await ev(kb(`return { docs: (await kb.documents.list()).length, hist: (await kb.qa.history()).length, fb: (await kb.feedback.list()).length };`));
    const w = r.value || {};
    check('12. After restarting, the reset holds', w.docs === 0 && w.hist === 0 && w.fb === 0, JSON.stringify(r));
  });
} catch (e) {
  check('The app started and responded', false, String(e));
} finally {
  rmSync(DATA, { recursive: true, force: true });
}
const total = 12;
const passed = results.filter((r) => r.ok).length;
console.log(JSON.stringify({ app: APP, passed, total, results }, null, 2));
