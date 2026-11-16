// Verificación independiente de la búsqueda de documentos (P07). Los agentes NO la ven.
// Abre la app real (Electron) con una carpeta de datos temporal, usa la API a través del puente
// del preload (window.knowledgeBase), reinicia la app para probar persistencia y revisa la interfaz.
// Uso: node --experimental-websocket scripts/p06-acceptance.mjs <carpeta-de-la-app> [puerto]
// Requiere que la app ya esté compilada (npm run build).
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
  throw new Error('la app no abrió una ventana');
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
    check('1. La interfaz tiene el puente', b.value === 'object', b.value); if (b.value !== 'object') return;
    await ev(kb(`for (const p of ${JSON.stringify(docs)}) { await kb.documents.import(p); } return true;`));
    const r = await ev(kb(`const all = (await kb.documents.list()).length;
      const t = (q) => kb.documents.search(q).then(x => x.length);
      return { all, vector: await t('vector'), upper: await t('VECTOR'), none: await t('zzqqxx-no-match'), empty: await t('') };`));
    const v = r.value || {};
    check('2. search() encuentra documentos por contenido', v.vector > 0 && v.vector <= v.all, JSON.stringify(r));
    check('3. search() no distingue mayúsculas', v.upper === v.vector, JSON.stringify(r));
    check('4. search() sin coincidencias devuelve vacío', v.none === 0, JSON.stringify(r));
    check('5. search(\'\') devuelve todos', v.empty === v.all, JSON.stringify(r));
    await ev('location.reload()'); await sleep(2500);
    const ui = await ev(`document.querySelectorAll('[aria-label="Search documents"]').length`);
    check('6. La interfaz tiene el campo "Search documents"', ui.value > 0, JSON.stringify(ui));
    const ask = await ev(kb(`await kb.indexing.start(); await new Promise(r => setTimeout(r, 1500)); const a = await kb.qa.ask('What did the team decide about the vector database?'); return a && a.citations ? a.citations.length : 0;`));
    check('7. Preguntar sigue funcionando (sin regresión)', ask.value > 0, JSON.stringify(ask));
  });
} catch (e) { check('La app arrancó', false, String(e)); } finally { rmSync(DATA, { recursive: true, force: true }); }
const total = 7; const passed = results.filter((r) => r.ok).length;
console.log(JSON.stringify({ app: APP, passed, total, results }, null, 2));
