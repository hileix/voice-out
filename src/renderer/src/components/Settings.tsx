import { useState, useEffect } from 'react'
import './Settings.css'

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

interface ElectronAPI {
  ipcRenderer: {
    send: (channel: string, ...args: unknown[]) => void
    on: (channel: string, listener: (event: unknown, data: unknown) => void) => void
    removeAllListeners: (channel: string) => void
  }
}

declare global {
  interface Window {
    electron: ElectronAPI
  }
}

const Settings = (): JSX.Element => {
  const [shortcut, setShortcut] = useState<Shortcut>({
    key: 's',
    modifiers: {
      control: true,
      shift: false,
      alt: false,
      meta: false
    }
  })
  const [isRecording, setIsRecording] = useState(false)

  // Load saved shortcut from electron store on component mount
  useEffect(() => {
    window.electron.ipcRenderer.on('get-shortcut-reply', (_, data) => {
      if (isValidShortcut(data)) {
        setShortcut(data)
      }
    })

    // Request the current shortcut from main process
    window.electron.ipcRenderer.send('get-shortcut')

    return (): void => {
      window.electron.ipcRenderer.removeAllListeners('get-shortcut-reply')
    }
  }, [])

  const startRecording = (): void => {
    setIsRecording(true)
  }

  const handleKeyDown = (e: React.KeyboardEvent): void => {
    if (!isRecording) return

    e.preventDefault()

    const newShortcut: Shortcut = {
      key: e.key.toLowerCase(),
      modifiers: {
        control: e.ctrlKey,
        shift: e.shiftKey,
        alt: e.altKey,
        meta: e.metaKey
      }
    }

    // Only update if at least one modifier is pressed and a key is selected
    if (
      (newShortcut.modifiers.control ||
        newShortcut.modifiers.shift ||
        newShortcut.modifiers.alt ||
        newShortcut.modifiers.meta) &&
      newShortcut.key !== 'control' &&
      newShortcut.key !== 'shift' &&
      newShortcut.key !== 'alt' &&
      newShortcut.key !== 'meta'
    ) {
      setShortcut(newShortcut)
      setIsRecording(false)

      // Save the new shortcut
      window.electron.ipcRenderer.send('set-shortcut', newShortcut)
    }
  }

  const resetToDefault = (): void => {
    const defaultShortcut: Shortcut = {
      key: 's',
      modifiers: {
        control: true,
        shift: false,
        alt: false,
        meta: false
      }
    }
    setShortcut(defaultShortcut)
    window.electron.ipcRenderer.send('set-shortcut', defaultShortcut)
  }

  const getShortcutDisplayText = (): string => {
    const modifiers: string[] = []
    if (shortcut.modifiers.control) modifiers.push('Ctrl')
    if (shortcut.modifiers.shift) modifiers.push('Shift')
    if (shortcut.modifiers.alt) modifiers.push('Alt')
    if (shortcut.modifiers.meta) modifiers.push('Cmd')

    const key = shortcut.key === ' ' ? 'Space' : shortcut.key.toUpperCase()

    return [...modifiers, key].join(' + ')
  }

  return (
    <div className="settings-container">
      <h2>Settings</h2>

      <div className="settings-section">
        <h3>Speak Shortcut</h3>
        <p className="settings-description">
          Configure the keyboard shortcut used to speak selected text
        </p>

        <div
          className={`shortcut-recorder ${isRecording ? 'recording' : ''}`}
          onClick={startRecording}
          onKeyDown={handleKeyDown}
          tabIndex={0}
        >
          {isRecording ? 'Press shortcut keys...' : getShortcutDisplayText()}
        </div>

        <div className="settings-buttons">
          <button className="reset-button" onClick={resetToDefault}>
            Reset to Default
          </button>
        </div>
      </div>
    </div>
  )
}

export default Settings
