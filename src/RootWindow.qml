import QtQml 2.12
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3
import Qt.labs.settings 1.0
import CCTV_Viewer.Core 1.0
import CCTV_Viewer.Models 1.0
import CCTV_Viewer.Utils 1.0
import CCTV_Viewer.Themes 1.0

ApplicationWindow {
    id: rootWindow

    title: qsTr("CCTV Viewer")

    visible: true
    visibility: Context.config.fullScreen ? Window.FullScreen : Window.Windowed
    width: rootWindowSettings.width
    height: rootWindowSettings.height

    // Right-to-left User Interfaces support
    LayoutMirroring.enabled: Qt.application.layoutDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    Binding {
        target: rootWindowSettings
        property: "width"
        value: rootWindow.width
        when: !Context.config.fullScreen
    }

    Binding {
        target: rootWindowSettings
        property: "height"
        value: rootWindow.height
        when: !Context.config.fullScreen
    }

    Settings {
        id: generalSettings

        fileName: Context.config.fileName
        property bool singleApplication: true
    }

    Settings {
        id: rootWindowSettings

        fileName: Context.config.fileName
        category: "RootWindow"
        property int width: 1280 + 48 // SideBar compact width
        property int height: 720
        property bool fullScreen
        property bool sidebarAutoCollapse: true

        Component.onCompleted: {
            // Do not initialize "fullScreen" if option "-f" is set
            if (!Context.config.fullScreen) {
                Context.config.fullScreen = rootWindowSettings.fullScreen;
            }

            rootWindowSettings.fullScreen = Qt.binding(function() { return Context.config.fullScreen; });
        }
    }

    Settings {
        id: layoutsCollectionSettings

        fileName: Context.config.fileName
        category: "ViewportsLayoutsCollection"

        property int currentIndex
        property string models
        // TODO: Move to "View"
        property bool presetIndicator: true
        // TODO: Move to "Viewport"
        property string defaultAVFormatOptions: JSON.stringify({
            "analyzeduration": 0, // 0 µs
            "probesize": 500000   // 500 KB
        })

        function toJSValue(key) {
            var obj = {};

            try {
                obj = JSON.parse(layoutsCollectionSettings[String(key)]);
            } catch(err) {
                Utils.log_error(qsTr("Error reading configuration!"));
            }

            return obj;
        }
    }

    Settings {
        id: viewSettings

        fileName: Context.config.fileName
        category: "View"

        property bool hideCursorWhenFullScreen: true
    }

    Settings {
        id: viewportSettings

        fileName: Context.config.fileName
        category: "Viewport"

        property bool unmuteWhenFullScreen: false
    }

    Settings {
        id: presetsSettings

        fileName: Context.config.fileName
        category: "Presets"

        property bool carouselRunning: false
        property int carouselInterval: 15000 // ms
    }

    Settings {
        id: themeSettings

        fileName: Context.config.fileName
        category: "Theme"

        property string accentColor
        property string viewportBackground
        property string viewportBorder
        property string viewportStatusText
        property string selectionBorder
        property string selectionFill
        property string fpsText
        property string fpsBackground
        property string overlayLabelBackground
        property string overlayLabelText
        property string sidebarText
        property string sidebarGroupTitle
        property string sidebarActiveItem
        property string conflictText
        property string discoveryHighlight
        property string discoveryHighlightText
        property string discoveryHighlightSecondary
        property string categoryHeaderBackground
        property string dialogBackground
        property string dialogText
        property string dialogInputBase
        property string dialogInputButton
        property string dialogDestructive
        property string paletteButton
        property string paletteButtonText
        property string paletteLight
        property string paletteMid
        property string paletteDark
        property string paletteToolTipBase
        property string paletteToolTipText

        Component.onCompleted: {
            if (accentColor) Compact.accentColor = accentColor;
            if (viewportBackground) Compact.viewportBackground = viewportBackground;
            if (viewportBorder) Compact.viewportBorder = viewportBorder;
            if (viewportStatusText) Compact.viewportStatusText = viewportStatusText;
            if (selectionBorder) Compact.selectionBorder = selectionBorder;
            if (selectionFill) Compact.selectionFill = selectionFill;
            if (fpsText) Compact.fpsText = fpsText;
            if (fpsBackground) Compact.fpsBackground = fpsBackground;
            if (overlayLabelBackground) Compact.overlayLabelBackground = overlayLabelBackground;
            if (overlayLabelText) Compact.overlayLabelText = overlayLabelText;
            if (sidebarText) Compact.sidebarText = sidebarText;
            if (sidebarGroupTitle) Compact.sidebarGroupTitle = sidebarGroupTitle;
            if (sidebarActiveItem) Compact.sidebarActiveItem = sidebarActiveItem;
            if (conflictText) Compact.conflictText = conflictText;
            if (discoveryHighlight) Compact.discoveryHighlight = discoveryHighlight;
            if (discoveryHighlightText) Compact.discoveryHighlightText = discoveryHighlightText;
            if (discoveryHighlightSecondary) Compact.discoveryHighlightSecondary = discoveryHighlightSecondary;
            if (categoryHeaderBackground) Compact.categoryHeaderBackground = categoryHeaderBackground;
            if (dialogBackground) Compact.dialogBackground = dialogBackground;
            if (dialogText) Compact.dialogText = dialogText;
            if (dialogInputBase) Compact.dialogInputBase = dialogInputBase;
            if (dialogInputButton) Compact.dialogInputButton = dialogInputButton;
            if (dialogDestructive) Compact.dialogDestructive = dialogDestructive;
            if (paletteButton) Compact.paletteButton = paletteButton;
            if (paletteButtonText) Compact.paletteButtonText = paletteButtonText;
            if (paletteLight) Compact.paletteLight = paletteLight;
            if (paletteMid) Compact.paletteMid = paletteMid;
            if (paletteDark) Compact.paletteDark = paletteDark;
            if (paletteToolTipBase) Compact.paletteToolTipBase = paletteToolTipBase;
            if (paletteToolTipText) Compact.paletteToolTipText = paletteToolTipText;

            // Apply theme colors to the Qt Controls palette
            rootWindow.palette.highlight = Compact.accentColor;
            rootWindow.palette.highlightedText = Compact.discoveryHighlightText;
            rootWindow.palette.button = Compact.paletteButton;
            rootWindow.palette.buttonText = Compact.paletteButtonText;
            rootWindow.palette.light = Compact.paletteLight;
            rootWindow.palette.mid = Compact.paletteMid;
            rootWindow.palette.dark = Compact.paletteDark;
            rootWindow.palette.toolTipBase = Compact.paletteToolTipBase;
            rootWindow.palette.toolTipText = Compact.paletteToolTipText;
        }
    }

    // ── Bindable action definitions ──────────────────────────────────
    // To add a new binding: add one entry here. The Key Bindings dialog,
    // config persistence, conflict detection, and Shortcut generation all
    // follow automatically. Actions with autoShortcut: false need manual
    // Shortcut blocks below (for custom enabled conditions or sequences).
    // The order below determines how items appear in the Key Bindings dialog.
    readonly property var actionDefs: [
        { id: "mute",              name: qsTr("Mute/Unmute"),            category: qsTr("Viewport"), default1: "M",         default2: "",
          action: function() { muteAction() } },
        { id: "viewportFullScreen", name: qsTr("Viewport fullscreen"),  category: qsTr("Viewport"), default1: "F",         default2: "",
          action: function() { /* TODO: viewport-level fullscreen */ } },
        { id: "focusUrl",          name: qsTr("Focus URL input"),       category: qsTr("Viewport"), default1: "Ctrl+L",    default2: "", autoShortcut: false,
          action: function() {
              if (Context.config.kioskMode) return;
              if (sideBarLoader.item && sideBarLoader.item.state === SideBar.Compact) {
                  sideBarLoader.item.state = SideBar.Popup;
              }
          } },
        { id: "nextPreset",        name: qsTr("Next preset"),           category: qsTr("Presets"),  default1: "Alt+Right", default2: "",
          action: function() { stackLayout.currentIndex = Math.min(stackLayout.currentIndex + 1, stackLayout.count - 1) } },
        { id: "prevPreset",        name: qsTr("Previous preset"),       category: qsTr("Presets"),  default1: "Alt+Left",  default2: "",
          action: function() { stackLayout.currentIndex = Math.max(stackLayout.currentIndex - 1, 0) } },
        { id: "carouselPause",     name: qsTr("Pause/Resume carousel"), category: qsTr("Presets"),  default1: "Space",     default2: "", autoShortcut: false,
          action: function() { carouselTimer.paused = !carouselTimer.paused } },
        { id: "fullScreen",        name: qsTr("Full screen"),           category: qsTr("Window"),   default1: "F11",       default2: "", autoShortcut: false,
          action: function() { Context.config.fullScreen = !Context.config.fullScreen } },
        { id: "quit",              name: qsTr("Quit app"),              category: qsTr("Window"),   default1: "Ctrl+Q",    default2: "",
          action: function() { Qt.quit() } }
    ]

    KeyBindingsDialog {
        id: keyBindingsDialog
        actionDefs: rootWindow.actionDefs
    }

    // ── Configurable key bindings ───────────────────────────────────
    function runAction(actionId) {
        for (var i = 0; i < actionDefs.length; ++i) {
            if (actionDefs[i].id === actionId) { actionDefs[i].action(); return; }
        }
    }

    function muteAction() {
        if (Utils.currentLayout().focusIndex >= 0) {
            var item = Utils.currentModel().get(Utils.currentLayout().focusIndex);
            var viewport = Utils.currentLayout().get(Utils.currentLayout().focusIndex);

            if (viewport.hasAudio) {
                item.volume = item.volume > 0 ? 0 : 1;
            }
        }
    }

    // Auto-generated shortcuts for actions without autoShortcut: false
    Repeater {
        model: actionDefs.length
        delegate: Item {
            visible: false
            property var def: actionDefs[index]
            property bool skip: def.autoShortcut === false

            Shortcut {
                sequence: skip ? "" : keyBindingsDialog.getBindingSlot(def.id, 1)
                enabled: !skip && sequence !== ""
                onActivated: def.action()
            }
            Shortcut {
                sequence: skip ? "" : keyBindingsDialog.getBindingSlot(def.id, 2)
                enabled: !skip && sequence !== ""
                onActivated: def.action()
            }
        }
    }

    // Shortcuts for the first 9 presets (Alt + 1, Alt + 2, ..., Alt + 9)
    Repeater {
        model: Context.config.kioskMode ? 0 : Math.min(stackLayout.count, 9)

        Item {
            Shortcut {
                sequence: "Alt+" + (index + 1)
                onActivated: stackLayout.currentIndex = index
            }
        }
    }

    // ── Special-case shortcuts (autoShortcut: false) ─────────────

    // Focus URL — needs sidebar awareness
    Shortcut {
        sequence: keyBindingsDialog.getBindingSlot("focusUrl", 1)
        enabled: sequence !== ""
        onActivated: runAction("focusUrl")
    }

    // Carousel pause — only active when carousel is running
    Shortcut {
        sequence: keyBindingsDialog.getBindingSlot("carouselPause", 1)
        enabled: presetsSettings.carouselRunning && sequence !== ""
        onActivated: runAction("carouselPause")
    }

    // Full screen — needs dual sequences
    Shortcut {
        sequence: keyBindingsDialog.getBindingSlot("fullScreen", 1)
        enabled: sequence !== ""
        onActivated: Context.config.fullScreen = !Context.config.fullScreen
    }
    Shortcut {
        sequences: [StandardKey.FullScreen]
        onActivated: Context.config.fullScreen = !Context.config.fullScreen
        onActivatedAmbiguously: Context.config.fullScreen = !Context.config.fullScreen
    }

    // Quit — uses StandardKey
    Shortcut {
        sequence: StandardKey.Quit
        onActivated: Qt.quit()
    }

    ViewportsLayoutsCollectionModel {
        id: layoutsCollectionModel

        // Demo group
        ViewportsLayoutModel {
            size: Qt.size(2, 2)
        }
        ViewportsLayoutModel {
            size: Qt.size(3, 3)
        }
        ViewportsLayoutModel {
            size: Qt.size(1, 1)
        }

        onCountChanged: stackLayout.currentIndex = stackLayout.currentIndex.clamp(0, layoutsCollectionModel.count - 1)
        Component.onCompleted: {
            // Demo streams
            get(0).get(0).url = "rtmp://live.a71.ru/demo/0";
            get(0).get(1).url = "rtmp://live.a71.ru/demo/1";

            try {
                if (!layoutsCollectionSettings.models.isEmpty()) {
                    fromJSValue(JSON.parse(layoutsCollectionSettings.models));
                }
            } catch(err) {
                Utils.log_error(qsTr("Error reading configuration!"));
            }

            layoutsCollectionModel.changed.connect(function () {
                layoutsCollectionSettings.models = JSON.stringify(toJSValue());
            });

            // Force initialize "currentIndex" if option "-p" is set
            var currentIndex = (Context.config.currentIndex >= 0) ? Context.config.currentIndex : layoutsCollectionSettings.currentIndex;
            stackLayout.currentIndex = currentIndex.clamp(0, layoutsCollectionModel.count - 1);
        }
    }

    Item {
        height: parent.height
        anchors.left: parent.left
        anchors.right: sideBarLoader.left

        StackLayout {
            id: stackLayout

            visible: false
            currentIndex: -1
            anchors.fill: parent

            onCurrentIndexChanged: {
                layoutsCollectionSettings.currentIndex = currentIndex;
                if (carouselTimer.running) {
                    carouselTimer.restart();
                }
            }

            Repeater {
                id: layoutRepeater
                model: layoutsCollectionModel

                ViewportsLayout {
                    model: layoutModel
                    focus: true
                }
            }

            Timer {
                id: carouselTimer

                repeat: true
                interval: presetsSettings.carouselInterval
                running: presetsSettings.carouselRunning && !paused

                property bool paused: false

                onTriggered: {
                    // Scrolling carousel to right
                    if (stackLayout.currentIndex < layoutsCollectionModel.count - 1) {
                        ++stackLayout.currentIndex
                    } else {
                        stackLayout.currentIndex = 0;
                    }
                }
            }
        }

        PresetIndicator {
            visible: layoutsCollectionSettings.presetIndicator && stackLayout.count > 1
            count: stackLayout.count
            currentIndex: stackLayout.currentIndex
            carouselState: presetsSettings.carouselRunning ? (carouselTimer.paused ? PresetIndicator.Paused : PresetIndicator.Running) : PresetIndicator.Disabled
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            onCurrentIndexChanged: stackLayout.currentIndex = currentIndex
            onCarouselControlClicked: carouselTimer.paused = (carouselState === PresetIndicator.Running ? true : false)
        }
    }


    Loader {
        id: sideBarLoader

        height: parent.height
        anchors.right: parent.right

        Component.onCompleted: {
            if (!Context.config.kioskMode) {
                source = "SideBar.qml";
            }
        }
    }

    MessageDialog {
        title: qsTr("Already running!")
        icon: StandardIcon.Warning
        text: qsTr("The application is already running!")
        informativeText: qsTr("Go to the first instance and allow multiple instances of the app to run in Settings.")
        standardButtons: MessageDialog.Ok

        onVisibilityChanged: !visible && Qt.quit();
        Component.onCompleted: {
            if (generalSettings.singleApplication && SingleApplication.isRunning()) {
                open();
            } else {
                stackLayout.visible = true;
            }
        }
    }

    SettingsDialog {
        id: settingsDialog
    }

    CursorShape {
        id: cursorShape

        autoHide: rootWindow.activeFocusItem != null && // Disabled when ApplicationWindow is't active
                  !settingsDialog.visible &&
                  (sideBarLoader.status === Loader.Null || sideBarLoader.item.state === SideBar.Compact) &&
                  Context.config.fullScreen && viewSettings.hideCursorWhenFullScreen
        autoHideTimeout: 3000
        anchors.fill: parent
    }
}
