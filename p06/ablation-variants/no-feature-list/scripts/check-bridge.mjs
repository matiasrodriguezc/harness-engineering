// Connects over Chrome DevTools to an Electron app opened with --remote-debugging-port
// and asks whether the window has access to the preload API (window.knowledgeBase).
// Usage: node --experimental-websocket scripts/check-bridge.mjs [port]
const port = process.argv[2] || '9333';
const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
const page = targets.find((t) => t.type === 'page');
if (!page) { console.log('No window open'); process.exit(2); }
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((r) => ws.addEventListener('open', r));
const ask = (expression) => new Promise((resolve) => {
  const id = Math.floor(Math.random() * 1e9);
  ws.addEventListener('message', function onMsg(ev) {
    const msg = JSON.parse(ev.data);
    if (msg.id === id) { ws.removeEventListener('message', onMsg); resolve(msg.result?.result?.value); }
  });
  ws.send(JSON.stringify({ id, method: 'Runtime.evaluate', params: { expression, returnByValue: true } }));
});
const bridge = await ask('typeof window.knowledgeBase');
const keys = await ask('window.knowledgeBase ? Object.keys(window.knowledgeBase).join(",") : ""');
const text = await ask('document.body.innerText.slice(0, 300)');
console.log(JSON.stringify({ bridge, keys, text }, null, 2));
ws.close();
