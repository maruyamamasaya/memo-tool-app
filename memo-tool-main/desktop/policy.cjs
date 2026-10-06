const APP_URL = 'https://maruyamamasaya.github.io/memo-tool/shared-memo/';
function isAppURL(value) { try { const url = new URL(value); return url.origin === new URL(APP_URL).origin && url.pathname.startsWith('/memo-tool/shared-memo/') } catch { return false } }
function isExternalURL(value) { try { return new URL(value).protocol === 'https:' } catch { return false } }
module.exports = { APP_URL, isAppURL, isExternalURL };
