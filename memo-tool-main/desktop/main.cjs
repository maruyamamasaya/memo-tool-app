const {app, BrowserWindow, Tray, Menu, nativeImage, globalShortcut, shell, ipcMain} = require('electron');
const path = require('node:path');
const {APP_URL,isAppURL,isExternalURL} = require('./policy.cjs');
const {createAuthBridge} = require('./auth-bridge.cjs');
let window, tray, quitting = false, bridge;
if (!app.requestSingleInstanceLock()) app.quit();
else {
app.on('second-instance', () => show());
function show() { window.show(); window.focus() }
function toggle() { window.isVisible() ? window.hide() : show() }
app.whenReady().then(() => {
  window = new BrowserWindow({width:720,height:820,minWidth:360,minHeight:480,title:'Shared Memo',webPreferences:{preload:path.join(__dirname,'preload.cjs'),contextIsolation:true,nodeIntegration:false,sandbox:true,partition:'persist:shared-memo'}});
  window.webContents.on('preload-error',(_event,_path,error)=>console.error('Login bridge preload failed: '+error.message));
  ipcMain.on('memo-ready',event=>{if(event.sender===window.webContents)console.info('Native login bridge ready')});
  window.on('close', event => { if(!quitting) { event.preventDefault(); window.hide() } });
  window.webContents.setWindowOpenHandler(({url}) => { if(isExternalURL(url)&&!isAppURL(url)) shell.openExternal(url); return {action:'deny'} });
  window.webContents.on('will-navigate', (event,url) => { if(!isAppURL(url)) {event.preventDefault();if(isExternalURL(url))shell.openExternal(url)} });
  window.webContents.session.setPermissionRequestHandler((contents,permission,callback) => callback(contents===window.webContents && isAppURL(contents.getURL()) && ['clipboard-sanitized-write','clipboard-read'].includes(permission)));
  window.webContents.session.setPermissionCheckHandler((contents,permission) => contents===window.webContents && isAppURL(contents.getURL()) && ['clipboard-sanitized-write','clipboard-read'].includes(permission));
  window.loadURL(APP_URL+'?desktop=1').catch(() => window.loadFile(path.join(__dirname,'offline.html')));
  const image=nativeImage.createFromPath(path.join(__dirname,'icon.png')).resize({width:18,height:18});
  tray=new Tray(image);tray.setToolTip('Shared Memo');tray.setContextMenu(Menu.buildFromTemplate([{label:'メモを開く',click:show},{label:'ブラウザで開く',click:()=>shell.openExternal(APP_URL)},{type:'separator'},{label:'終了',click:()=>app.quit()}]));tray.on('click',toggle);
  const shortcut=globalShortcut.register('CommandOrControl+Shift+M',toggle);
  Menu.setApplicationMenu(Menu.buildFromTemplate([{label:'Shared Memo',submenu:[{label:'メモを開く',click:show},{label:'再読み込み',click:()=>window.webContents.reloadIgnoringCache()},{label:shortcut?'ショートカット: ⌘/Ctrl+Shift+M':'ショートカット登録不可',enabled:false},{type:'separator'},{role:'quit'}]},{role:'editMenu'}]));
  ipcMain.handle('memo-login', async event => {
    if(event.sender!==window.webContents||!isAppURL(event.senderFrame.url))throw Error('Invalid sender');
    bridge?.close();bridge=await createAuthBridge(credential=>{window.webContents.send('memo-credential',credential);show()});
    await shell.openExternal(bridge.url);
  });
});
app.on('activate',show);
app.on('before-quit',()=>{quitting=true;bridge?.close();globalShortcut.unregisterAll()});
}
