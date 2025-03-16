import { useState, useEffect } from 'react'
import Settings from './components/Settings'
import electronLogo from './assets/electron.svg'
import './App.css'

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

// Helper function to validate shortcut data
const isValidShortcut = (data: unknown): data is Shortcut => {
  return (
    data !== null &&
    typeof data === 'object' &&
    'key' in data &&
    'modifiers' in data &&
    typeof (data as Shortcut).key === 'string' &&
    typeof (data as Shortcut).modifiers === 'object'
  )
}

function App(): JSX.Element {
  const [showSettings, setShowSettings] = useState(false)
  const [currentShortcut, setCurrentShortcut] = useState<Shortcut>({
    key: 's',
    modifiers: {
      control: true,
      shift: false,
      alt: false,
      meta: false
    }
  })

  useEffect(() => {
    window.electron.ipcRenderer.on('get-shortcut-reply', (_, data) => {
      if (isValidShortcut(data)) {
        setCurrentShortcut(data)
      }
    })

    // Also listen for shortcut changes from settings
    window.electron.ipcRenderer.on('shortcut-changed', (_, data) => {
      if (isValidShortcut(data)) {
        setCurrentShortcut(data)
      }
    })

    // Request the current shortcut from main process
    window.electron.ipcRenderer.send('get-shortcut')

    return (): void => {
      window.electron.ipcRenderer.removeAllListeners('get-shortcut-reply')
      window.electron.ipcRenderer.removeAllListeners('shortcut-changed')
    }
  }, [])

  const getShortcutDisplayText = (): string => {
    const modifiers: string[] = []
    if (currentShortcut.modifiers.control) modifiers.push('Ctrl')
    if (currentShortcut.modifiers.shift) modifiers.push('Shift')
    if (currentShortcut.modifiers.alt) modifiers.push('Alt')
    if (currentShortcut.modifiers.meta) modifiers.push('Cmd')

    const key = currentShortcut.key === ' ' ? 'Space' : currentShortcut.key.toUpperCase()

    return [...modifiers, key].join(' + ')
  }

  return (
    <div className="app-container">
      {showSettings ? (
        <div className="settings-view">
          <Settings />
          <button className="back-button" onClick={() => setShowSettings(false)}>
            Back to Main
          </button>
        </div>
      ) : (
        <div className="main-view">
          <div className="text">Voice Out - Speak selected text with customizable shortcuts</div>
          <p className="tip">
            Press <code>{getShortcutDisplayText()}</code> to speak selected text
          </p>
          <div className="actions">
            <div className="action">
              <a
                href="#"
                onClick={(e) => {
                  e.preventDefault()
                  setShowSettings(true)
                }}
              >
                Settings
              </a>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default App
