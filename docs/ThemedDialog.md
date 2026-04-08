# ThemedDialog

A dark-themed (based on your color scheme), fully QML-rendered dialog window that serves as a drop-in replacement for `QtQuick.Dialogs 1.3` `Dialog`. Uses the Compact theme system for all colors, making it fully configurable via the `[Theme]` section of the config file.

## Why ThemedDialog?

The `QtQuick.Dialogs 1.3` `Dialog` wraps a platform-native `QDialog`, which means:
- Colors/styling are controlled by the OS, not the app
- Can't prevent close on OK (for validation)
- No shake or other feedback animations
- ComboBox popups inside the dialog can have wrong colors (white-on-white)
- Dialog positioning is OS-controlled

ThemedDialog solves all of these by using a QML `Window` with `Qt.Dialog` flags, wrapping content in a `Pane` for palette propagation (since `Window.palette` isn't available in Qt 5.12).

## Quick Start

### Converting from QtQuick.Dialogs 1.3

**Before:**
```qml
import QtQuick.Dialogs 1.3

Dialog {
    title: "Settings"
    modality: Qt.ApplicationModal
    standardButtons: StandardButton.Ok | StandardButton.Cancel

    onAccepted: saveSettings()

    ColumnLayout {
        Label { text: "Content" }
        TextField { id: nameField }
    }
}
```

**After:**
```qml
ThemedDialog {
    title: "Settings"

    onAccepted: {
        saveSettings()
        close()
    }

    ColumnLayout {
        anchors.fill: parent
        Label { text: "Content" }
        TextField { id: nameField }
    }
}
```

### Changes required:

1. Replace `Dialog {` with `ThemedDialog {`
2. Remove `import QtQuick.Dialogs 1.3`
3. Remove `standardButtons:` and `modality:` (handled by defaults)
4. Add `anchors.fill: parent` to root content layout
5. Add `close()` call in `onAccepted` handler
6. Map `standardButtons` flags to `show*Button` properties (see table below)

## StandardButton Mapping

| v1.3 `standardButtons` | ThemedDialog property |
|---|---|
| `StandardButton.Ok` | `showOkButton: true` (default) |
| `StandardButton.Cancel` | `showCancelButton: true` (default) |
| `StandardButton.RestoreDefaults` / `StandardButton.Reset` | `showResetButton: true` |
| `StandardButton.Apply` | `showApplyButton: true` |
| `StandardButton.Help` | `showHelpButton: true` |
| `StandardButton.Yes` | `showYesButton: true` |
| `StandardButton.No` | `showNoButton: true` |
| `StandardButton.Discard` | `showDiscardButton: true` |

## Properties

### Button Visibility
All default to `false` except `showOkButton` and `showCancelButton` which default to `true`.

| Property | Type | Default | Description |
|---|---|---|---|
| `showOkButton` | bool | true | Show OK button (AcceptRole, accent color) |
| `showCancelButton` | bool | true | Show Cancel button (RejectRole) |
| `showResetButton` | bool | false | Show Restore Defaults button (ResetRole, left side) |
| `showApplyButton` | bool | false | Show Apply button (ApplyRole) |
| `showHelpButton` | bool | false | Show Help button (HelpRole, left side) |
| `showYesButton` | bool | false | Show Yes button (YesRole, accent color) |
| `showNoButton` | bool | false | Show No button (NoRole) |
| `showDiscardButton` | bool | false | Show Discard button (DestructiveRole, red) |

### Button Text
All have sensible defaults using `qsTr()` for i18n.

| Property | Type | Default |
|---|---|---|
| `okText` | string | "OK" |
| `cancelText` | string | "Cancel" |
| `resetText` | string | "Restore Defaults" |
| `applyText` | string | "Apply" |
| `helpText` | string | "Help" |
| `yesText` | string | "Yes" |
| `noText` | string | "No" |
| `discardText` | string | "Discard" |

### Button State

| Property | Type | Default | Description |
|---|---|---|---|
| `okEnabled` | bool | true | Enable/disable OK button. Combine with `shake()` for validation feedback. |

### Other Properties

| Property | Type | Description |
|---|---|---|
| `clickedButton` | string | Read-only. The last button clicked: "ok", "cancel", "reset", etc. |
| `contentData` | alias | Default property. Direct children are placed in the content area. |
| `leftButtons` | alias | Custom buttons on the left side of the button bar. |

### Modality

ThemedDialog defaults to `Qt.ApplicationModal`, which blocks interaction with the main window while the dialog is open. This also suppresses application-level keyboard shortcuts (e.g. custom key bindings) while the dialog has focus.

To create a non-modal dialog, override the `modality` property:

```qml
ThemedDialog {
    title: "Stream Info"
    modality: Qt.NonModal

    showCancelButton: false
    okText: "Close"

    onAccepted: close()

    Label {
        anchors.fill: parent
        text: streamInfoText
        wrapMode: Text.Wrap
    }
}
```

Non-modal dialogs allow interaction with the main window while open. Application keyboard shortcuts remain active in the main window.

| Value | Behavior |
|---|---|
| `Qt.ApplicationModal` | Blocks all app windows (default) |
| `Qt.WindowModal` | Blocks only the parent window |
| `Qt.NonModal` | No blocking — main window stays interactive |

### Shortcuts and modal dialogs

By default, `Shortcut` components in the main window use `Qt.WindowShortcut` context, which means they are suppressed while a modal ThemedDialog is open. This is usually the desired behavior — you don't want "M" (mute) firing while the user is typing in a dialog text field.

If a specific shortcut must remain active even while a modal dialog is open, set its `context` to `Qt.ApplicationShortcut`:

```qml
// In RootWindow.qml
Shortcut {
    sequence: "F11"
    context: Qt.ApplicationShortcut  // fires even over modal dialogs
    onActivated: toggleFullScreen()
}
```

Use this sparingly — only for shortcuts that make sense regardless of what the user is doing (e.g. fullscreen toggle, emergency stop). Most shortcuts should respect dialog modality.

| Shortcut context | Fires over modal dialog? |
|---|---|
| `Qt.WindowShortcut` | No (default) |
| `Qt.ApplicationShortcut` | Yes |

### Interaction with the key bindings system

The configurable key bindings system (see `KeyBindingsDialog`) generates `Shortcut` components with `Qt.WindowShortcut` context. This means all user-configured bindings are automatically suppressed while any modal ThemedDialog is open, including:

- The Settings dialog
- The Key Bindings dialog itself (important — key capture works because the dialog handles `Keys.onPressed` directly, not through `Shortcut` components)
- Any future dialogs built with ThemedDialog

This is the correct behavior: the Key Bindings dialog needs to capture raw key presses for binding assignment, and having the main window's shortcuts fire simultaneously would conflict. No special handling is needed — Qt's modality system handles the suppression.

To add a new bindable action that should work even during dialogs, add it to `actionDefs` with `autoShortcut: false` and create a manual `Shortcut` block with `context: Qt.ApplicationShortcut`:

```qml
// In RootWindow.qml

// 1. Add the action definition (autoShortcut: false prevents the
//    Repeater from generating a Qt.WindowShortcut for it)
readonly property var actionDefs: [
    // ... existing actions ...
    { id: "emergencyStop",  name: qsTr("Emergency stop"),
      category: qsTr("Window"), default1: "Ctrl+Shift+X", default2: "",
      autoShortcut: false,
      action: function() { stopAllStreams() } }
]

// 2. Create a manual Shortcut with Qt.ApplicationShortcut context
//    so it fires even when a modal dialog is open
Shortcut {
    sequence: keyBindingsDialog.getBindingSlot("emergencyStop", 1)
    context: Qt.ApplicationShortcut
    enabled: sequence !== ""
    onActivated: runAction("emergencyStop")
}
```

## Signals

All v1.3 Dialog signals are supported:

| Signal | Emitted when | Auto-closes? |
|---|---|---|
| `accepted()` | OK clicked or Enter pressed | **No** (call `close()` yourself) |
| `rejected()` | Cancel clicked or Escape pressed | Yes |
| `reset()` | Restore Defaults clicked | No |
| `apply()` | Apply clicked | No |
| `discard()` | Discard clicked | No |
| `help()` | Help clicked | No |
| `yes()` | Yes clicked | Yes |
| `no()` | No clicked | Yes |
| `buttonClicked()` | Any button clicked | — |
| `actionChosen(action)` | Any button/key action | — |

### actionChosen signal

The `action` parameter is a JavaScript object:
```javascript
{
    "button": "ok",    // button identifier string
    "key": 0,          // key code if triggered by keyboard, 0 otherwise
    "accepted": true   // set to false to prevent the action
}
```

Set `action.accepted = false` in your `onActionChosen` handler to prevent the button action from firing. This is useful for confirmation dialogs or complex validation:

```qml
onActionChosen: {
    if (action.button === "discard") {
        // Ask for confirmation before discarding
        if (!confirmDiscard()) {
            action.accepted = false
        }
    }
}
```

## Methods

| Method | Description |
|---|---|
| `open()` | Show dialog centered on the main application window |
| `close()` | Close the dialog (inherited from Window) |
| `click(button)` | Programmatically trigger a button action. Takes a string: "ok", "cancel", "reset", "apply", "discard", "help", "yes", "no" |
| `shake()` | Shake the dialog window horizontally for validation feedback |

## Keyboard Handling

Matches v1.3 Dialog behavior:

| Key | Action |
|---|---|
| Enter / Return | Triggers OK (if enabled) |
| Escape | Triggers Cancel (or closes if no Cancel button) |

## Button Bar Layout

Follows platform conventions:

```
[Reset] [Help] [Custom...] ──────── [Apply] [Discard] [No] [Yes] [Cancel] [OK]
└── Left side ──────────────────────┘        └── Right side ──────────────────┘
```

- Reset and Help appear on the left (per GNOME/KDE conventions)
- Custom `leftButtons` appear after Help
- Discard is styled with a red/destructive color
- Yes and OK use the accent color
- All other buttons use the standard neutral style

All button bar buttons are `ThemedButton` instances (see below).

## ThemedButton

A companion component for use inside ThemedDialog. Provides consistent dark-themed button styling without needing to override `background` and `contentItem` on every button.

### Variants

| Property | Style | Use Case |
|---|---|---|
| (default) | Dark background, light text, mid border | Standard actions (Clear, Cancel) |
| `accent: true` | Accent (teal) background, white text | Primary actions (OK, Save, Discover) |
| `destructive: true` | Red background, white text | Dangerous actions (Discard, Delete) |
| `active: true` | Accent background (dynamic toggle) | Toggled state (key capture active) |

All variants handle `enabled: false` automatically (dimmed colors).

### Examples

```qml
// Standard button
ThemedButton {
    text: "Clear"
    onClicked: clearField()
}

// Primary action
ThemedButton {
    text: "Save"
    accent: true
    onClicked: save()
}

// Destructive action
ThemedButton {
    text: "Delete"
    destructive: true
    onClicked: confirmDelete()
}

// Dynamic toggle (e.g. key capture mode)
ThemedButton {
    text: capturing ? "Press key..." : binding
    active: capturing
    onClicked: startCapture()
}
```

### Properties

| Property | Type | Default | Description |
|---|---|---|---|
| `accent` | bool | false | Use accent color for primary actions |
| `destructive` | bool | false | Use red/destructive color (takes precedence over accent) |
| `active` | bool | false | Dynamic accent highlight for toggled states |

All standard `Button` properties (`text`, `enabled`, `font`, `onClicked`, etc.) work as expected.

## Theme Integration

All colors come from `Compact.*` properties, which are configurable via the `[Theme]` section of the config file:

| Theme property | What it controls |
|---|---|
| `dialogBackground` | Window and pane background |
| `dialogText` | All text (labels, buttons, group titles) |
| `dialogInputBase` | TextField and ComboBox input backgrounds |
| `dialogInputButton` | Button backgrounds |
| `dialogDestructive` | Discard button color |
| `accentColor` | OK and Yes button backgrounds, highlights |
| `paletteMid` | Button borders, separators |
| `paletteDark` | Dark shades, disabled states |
| `sidebarText` | Button text color |
| `discoveryHighlightText` | Accent button text (white on teal) |
| `conflictText` | Error/conflict text color |

## Examples

### Simple OK/Cancel dialog (default)
```qml
ThemedDialog {
    title: "Confirm"
    onAccepted: {
        doSomething()
        close()
    }

    Label {
        anchors.centerIn: parent
        text: "Are you sure?"
    }
}
```

### Yes/No dialog
```qml
ThemedDialog {
    title: "Save Changes?"
    showOkButton: false
    showCancelButton: false
    showYesButton: true
    showNoButton: true
    showDiscardButton: true
    discardText: "Don't Save"

    onYes: saveAndClose()
    onNo: { /* do nothing, dialog auto-closes */ }
    onDiscard: closeWithoutSaving()

    Label {
        anchors.centerIn: parent
        text: "You have unsaved changes."
    }
}
```

### Dialog with validation and shake
```qml
ThemedDialog {
    title: "New Preset"

    onAccepted: {
        if (nameField.text.trim() === "") {
            shake()
            return
        }
        createPreset(nameField.text)
        close()
    }

    ColumnLayout {
        anchors.fill: parent
        Label { text: "Preset name:" }
        TextField {
            id: nameField
            Layout.fillWidth: true
            placeholderText: "Enter a name"
        }
    }
}
```

### Dialog with Restore Defaults and Apply
```qml
ThemedDialog {
    title: "Preferences"
    showResetButton: true
    showApplyButton: true

    onAccepted: { savePrefs(); close() }
    onApply: savePrefs()
    onReset: loadDefaults()

    ColumnLayout {
        anchors.fill: parent
        // preference controls...
    }
}
```

### Dialog with custom left buttons
```qml
ThemedDialog {
    title: "Export"

    leftButtons: [
        ThemedButton {
            text: "Preview..."
            onClicked: showPreview()
        }
    ]

    onAccepted: { exportData(); close() }

    // content...
}
```

## v1.3 Inheritance Tree Coverage

The `QtQuick.Dialogs 1.3` Dialog is built from three layers:

```
QQuickAbstractDialog (C++)          — base window, signals, open/close
  └── QQuickDialog1 (C++)           — standardButtons, click(), role signals
        └── DefaultDialogWrapper (QML) — visual layout, key handling, actionChosen
```

ThemedDialog covers all three layers:

### QQuickAbstractDialog coverage
| Item | v1.3 | ThemedDialog | Notes |
|---|---|---|---|
| `visible` | ✅ | ✅ | Inherited from Window |
| `modality` | ✅ | ✅ | Set to `Qt.ApplicationModal` by default |
| `title` | ✅ | ✅ | Inherited from Window |
| `x`, `y`, `width`, `height` | ✅ | ✅ | Inherited from Window |
| `isWindow` | ✅ | — | Always true (is a Window) |
| `visibilityChanged` | ✅ | ✅ | Window emits `onVisibleChanged` |
| `geometryChanged` | ✅ | ✅ | Inherited from Window |
| `accepted()` | ✅ | ✅ | Does NOT auto-close |
| `rejected()` | ✅ | ✅ | Auto-closes |
| `open()` | ✅ | ✅ | Centers on rootWindow |
| `close()` | ✅ | ✅ | Inherited from Window |
| Window close button (×) | → rejected | ✅ | `onClosing` emits `rejected()` |

### QQuickDialog1 coverage
| Item | v1.3 | ThemedDialog | Notes |
|---|---|---|---|
| `standardButtons` | Bitfield enum | `show*Button` bools | Different API, same result |
| `clickedButton` | StandardButton enum | String | "ok", "cancel", etc. |
| `contentItem` | default property | `contentData` default | Direct children work the same |
| `buttonClicked` | ✅ | ✅ | Fires for any button |
| `discard()` | ✅ | ✅ | Via `showDiscardButton` |
| `help()` | ✅ | ✅ | Via `showHelpButton` |
| `yes()` | ✅ | ✅ | Via `showYesButton` |
| `no()` | ✅ | ✅ | Via `showNoButton` |
| `apply()` | ✅ | ✅ | Via `showApplyButton` |
| `reset()` | ✅ | ✅ | Via `showResetButton` |
| `click(button)` | StandardButton enum | String | `click("ok")` instead of `click(StandardButton.Ok)` |

### DefaultDialogWrapper coverage
| Item | v1.3 | ThemedDialog | Notes |
|---|---|---|---|
| `data` (default property) | ✅ | ✅ | Direct children go to content area |
| `actionChosen(action)` | ✅ | ✅ | Same `{button, key, accepted}` API |
| Enter → OK | ✅ | ✅ | Only if `okEnabled` |
| Escape → Cancel | ✅ | ✅ | Falls back to `close()` if no Cancel |
| `SystemPalette` colors | Platform | Compact theme | Fully configurable via config |
| Left/Right button layout | Flow + Repeater | RowLayout + Loaders | Same visual order |

### StandardButton enum mapping
v1.3 uses integer enums; ThemedDialog uses strings for `click()`:

| v1.3 Enum | ThemedDialog string | Role |
|---|---|---|
| `StandardButton.Ok` | `"ok"` | AcceptRole |
| `StandardButton.Cancel` | `"cancel"` | RejectRole |
| `StandardButton.Save` | — | Not implemented (use "ok" with `okText: "Save"`) |
| `StandardButton.Open` | — | Not implemented (use "ok" with `okText: "Open"`) |
| `StandardButton.Yes` | `"yes"` | YesRole |
| `StandardButton.No` | `"no"` | NoRole |
| `StandardButton.Abort` | — | Not implemented (use "cancel" with `cancelText: "Abort"`) |
| `StandardButton.Retry` | — | Not implemented (use "ok" with `okText: "Retry"`) |
| `StandardButton.Ignore` | — | Not implemented (use "ok" with `okText: "Ignore"`) |
| `StandardButton.Close` | — | Not implemented (use "cancel" with `cancelText: "Close"`) |
| `StandardButton.Discard` | `"discard"` | DestructiveRole |
| `StandardButton.Apply` | `"apply"` | ApplyRole |
| `StandardButton.Reset` | `"reset"` | ResetRole |
| `StandardButton.RestoreDefaults` | `"reset"` | ResetRole |
| `StandardButton.Help` | `"help"` | HelpRole |
| `StandardButton.YesToAll` | — | Not implemented |
| `StandardButton.NoToAll` | — | Not implemented |
| `StandardButton.SaveAll` | — | Not implemented |

Note: Buttons like Save, Open, Retry, Ignore, Close, and Abort are not separate
buttons — they share roles with OK or Cancel. To replicate them, use the
corresponding show property and change the button text:
```qml
ThemedDialog {
    showOkButton: true
    okText: "Save"        // replaces StandardButton.Save
    showCancelButton: true
    cancelText: "Close"   // replaces StandardButton.Close
}
```

## Differences from v1.3 Dialog

| Feature | v1.3 Dialog | ThemedDialog |
|---|---|---|
| Rendering | Platform-native (QDialog) | Pure QML (Window) |
| Theme | OS-controlled | Compact theme system |
| `onAccepted` auto-close | Yes | **No** (call `close()`) |
| Button disable | Not possible | `okEnabled: false` |
| Shake feedback | Not possible | `shake()` |
| Prevent close | Not possible | Don't call `close()` in handler |
| `actionChosen` intercept | Via `action.accepted` | Same API |
| `standardButtons` | Bitfield enum | Individual `show*Button` bools |
| `click()` parameter | `StandardButton` enum | String ("ok", "cancel", etc.) |
| `clickedButton` | `StandardButton` enum | String |
| Keyboard Enter→OK | Yes | Yes |
| Keyboard Escape→Cancel | Yes | Yes |
| Window close (×) | Triggers rejected | Triggers rejected (same) |
| Centers on parent | OS-dependent | Always (via `open()`) |
| Palette propagation | Platform | Via Pane (Qt 5.12 compatible) |
| `contentItem` | Platform layout | `contentData` default property |
| Min Qt version | 5.0 | 5.12 |
