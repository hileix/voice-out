import { app, shell, BrowserWindow, ipcMain, globalShortcut } from 'electron'
import { join } from 'path'
import { electronApp, optimizer, is } from '@electron-toolkit/utils'
import icon from '../../resources/icon.png?asset'
import say from 'say'
import { getSelectionText } from '@xitanggg/node-selection'

// Define the shortcut type
type Shortcut = {
  key: string
  modifiers: {
    control: boolean
    shift: boolean
    alt: boolean
    meta: boolean
  }
}

// Default shortcut configuration
let currentShortcut: Shortcut = {
  key: 's',
  modifiers: {
    control: true,
    shift: false,
    alt: false,
    meta: false
  }
}

// Function to convert shortcut object to Electron shortcut string
function getElectronAccelerator(shortcut: Shortcut): string {
  const modifiers: string[] = []
  if (shortcut.modifiers.control) modifiers.push('Control')
  if (shortcut.modifiers.shift) modifiers.push('Shift')
  if (shortcut.modifiers.alt) modifiers.push('Alt')
  if (shortcut.modifiers.meta) modifiers.push('CommandOrControl')

  const key = shortcut.key.length === 1 ? shortcut.key.toUpperCase() : shortcut.key

  return [...modifiers, key].join('+')
}

// Register the shortcut
function registerSpeakShortcut(shortcut: Shortcut): boolean {
  try {
    // Unregister existing shortcut if any
    globalShortcut.unregisterAll()

    // Register the new shortcut
    const accelerator = getElectronAccelerator(shortcut)
    return globalShortcut.register(accelerator, async () => {
      const selectionText = getSelectionText()
      console.log('selectionText:', selectionText)
      if (selectionText && selectionText.trim() !== '') {
        say.speak(selectionText)
      }
    })
  } catch (error) {
    console.error('Failed to register shortcut:', error)
    return false
  }
}

function createWindow(): void {
  // Create the browser window.
  const mainWindow = new BrowserWindow({
    width: 900,
    height: 670,
    show: false,
    autoHideMenuBar: true,
    ...(process.platform === 'linux' ? { icon } : {}),
    webPreferences: {
      preload: join(__dirname, '../preload/index.js'),
      sandbox: false
    }
  })

  mainWindow.on('ready-to-show', () => {
    mainWindow.show()
  })

  mainWindow.webContents.setWindowOpenHandler((details) => {
    shell.openExternal(details.url)
    return { action: 'deny' }
  })

  // HMR for renderer base on electron-vite cli.
  // Load the remote URL for development or the local html file for production.
  if (is.dev && process.env['ELECTRON_RENDERER_URL']) {
    mainWindow.loadURL(process.env['ELECTRON_RENDERER_URL'])
  } else {
    mainWindow.loadFile(join(__dirname, '../renderer/index.html'))
  }
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.whenReady().then(() => {
  // Set app user model id for windows
  electronApp.setAppUserModelId('com.electron')

  // Default open or close DevTools by F12 in development
  // and ignore CommandOrControl + R in production.
  // see https://github.com/alex8088/electron-toolkit/tree/master/packages/utils
  app.on('browser-window-created', (_, window) => {
    optimizer.watchWindowShortcuts(window)
  })

  // IPC test
  ipcMain.on('ping', () => console.log('pong'))

  // Register the default shortcut
  registerSpeakShortcut(currentShortcut)

  // Handle get-shortcut request from renderer
  ipcMain.on('get-shortcut', (event) => {
    event.reply('get-shortcut-reply', currentShortcut)
  })

  // Handle set-shortcut request from renderer
  ipcMain.on('set-shortcut', (_, shortcut: Shortcut) => {
    // Update current shortcut
    currentShortcut = shortcut

    // Re-register the shortcut
    registerSpeakShortcut(currentShortcut)

    // Notify all windows about the shortcut change
    BrowserWindow.getAllWindows().forEach((window) => {
      window.webContents.send('shortcut-changed', currentShortcut)
    })
  })

  createWindow()

  app.on('activate', function () {
    // On macOS it's common to re-create a window in the app when the
    // dock icon is clicked and there are no other windows open.
    if (BrowserWindow.getAllWindows().length === 0) createWindow()
  })
})

// Quit when all windows are closed, except on macOS. There, it's common
// for applications and their menu bar to stay active until the user quits
// explicitly with Cmd + Q.
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

// Unregister all shortcuts when app is about to quit
app.on('will-quit', () => {
  globalShortcut.unregisterAll()
})

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and require them here.
