pragma Singleton

import QtQml 2.12
import QtQuick 2.12

QtObject {
    // Layout constants
    readonly property real radius: 4
    readonly property real spacing: 6
    readonly property real buttonPadding: 6
    readonly property real contentPadding: 10

    // Tooltip timing
    readonly property int toolTipDelay: 500
    readonly property int toolTipTimeout: 3000

    // ── Theme Colors ──────────────────────────────────────────────────
    // Override these via [Theme] section in the config file.
    // RootWindow loads overrides at startup.

    // Accent / highlight
    property color accentColor: "#17a9ca"

    // Viewport
    property color viewportBackground: "black"
    property color viewportBorder: "#101010"
    property color viewportStatusText: "white"

    // Selection / focus
    property color selectionBorder: "#00dd00"
    property color selectionFill: "#4000a8ff"

    // FPS overlay
    property color fpsText: "lime"
    property color fpsBackground: "#80000000"

    // Preset label overlay
    property color overlayLabelBackground: "#C0000000"
    property color overlayLabelText: "white"

    // Sidebar
    property color sidebarText: "white"
    property color sidebarGroupTitle: "white"
    property color sidebarActiveItem: "#17a9ca"

    // Dialogs
    property color conflictText: "red"

    // Discovery list
    property color discoveryHighlight: "#17a9ca"
    property color discoveryHighlightText: "white"
    property color discoveryHighlightSecondary: "#D0D0D0"

    // Key bindings dialog
    property color categoryHeaderBackground: "#14ffffff"

    // Dark dialog palette (for Window-based dialogs)
    property color dialogBackground: "#353637"
    property color dialogText: "white"
    property color dialogInputBase: "#4a4b4d"
    property color dialogInputButton: "#4a4b4d"
    property color dialogDestructive: "#c0392b"

    // Qt Controls palette (mirrors qtquickcontrols2.conf defaults)
    property color paletteButton: "#e0e0e0"
    property color paletteButtonText: "#26282a"
    property color paletteLight: "#f6f6f6"
    property color paletteMid: "#bdbdbd"
    property color paletteDark: "#353637"
    property color paletteToolTipBase: "#ffffff"
    property color paletteToolTipText: "#000000"
}
