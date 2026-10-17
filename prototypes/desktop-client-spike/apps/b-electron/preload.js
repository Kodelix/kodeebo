// PROTOTYPE - NOT FOR PRODUCTION
// Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
// Date: 2026-10-17
'use strict';
const { contextBridge, ipcRenderer } = require('electron');
contextBridge.exposeInMainWorld('api', {
  painted: (ms) => ipcRenderer.send('painted', ms),
  closeBill: () => ipcRenderer.invoke('close-bill'),
});
