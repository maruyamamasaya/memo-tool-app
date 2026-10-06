const http = require('node:http');
const crypto = require('node:crypto');
const { APP_URL } = require('./policy.cjs');
function createAuthBridge(onCredential, timeoutMs = 180000) {
  const state = crypto.randomBytes(32).toString('hex');
  let used = false;
  const origin = new URL(APP_URL).origin;
  const server = http.createServer((req, res) => {
    if (req.headers.origin !== origin || req.url !== '/auth') { res.writeHead(403); res.end(); return }
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    res.setHeader('Access-Control-Allow-Private-Network', 'true');
    res.setHeader('Cache-Control', 'no-store');
    if (req.method === 'OPTIONS') { res.writeHead(204); res.end(); return }
    if (req.method !== 'POST' || used) { res.writeHead(405); res.end(); return }
    let body = '';
    req.on('data', data => { body += data; if (body.length > 20000) req.destroy() });
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        if (typeof data.state !== 'string' || data.state.length !== state.length || !crypto.timingSafeEqual(Buffer.from(data.state), Buffer.from(state)) || typeof data.idToken !== 'string' || data.idToken.length > 15000) throw Error('Invalid callback');
        used = true; res.writeHead(200); res.end('OK'); onCredential({idToken:data.idToken}); setImmediate(() => close());
      } catch { res.writeHead(400); res.end('Invalid callback') }
    });
  });
  const timer = setTimeout(close, timeoutMs); timer.unref();
  function close() { clearTimeout(timer); server.close() }
  return new Promise((resolve, reject) => {
    server.on('error', reject);
    server.listen(0, '127.0.0.1', () => resolve({url:APP_URL+'#desktopLogin='+server.address().port+'&state='+state,close,port:server.address().port,state}));
  });
}
module.exports = {createAuthBridge};
