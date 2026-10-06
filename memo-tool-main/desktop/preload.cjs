const {contextBridge, ipcRenderer} = require('electron');
contextBridge.exposeInMainWorld('memoDesktop', {
  login: () => ipcRenderer.invoke('memo-login'),
  onCredential: callback => { ipcRenderer.on('memo-credential', (_event, credential) => callback(credential)) }
});

ipcRenderer.send('memo-ready');
