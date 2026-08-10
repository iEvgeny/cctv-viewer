import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import CCTV_Viewer.Themes 1.0

/*!
    \qmltype ThemedDialog
    \brief A dark-themed dialog window — drop-in replacement for QtQuick.Dialogs 1.3 Dialog.

    ThemedDialog provides a consistent, fully-themeable dialog that uses the
    Compact theme system for all colors. It is designed to make converting
    existing QtQuick.Dialogs 1.3 Dialog instances straightforward.

    \section1 Converting from QtQuick.Dialogs 1.3

    Before (v1.3):
    \code
    import QtQuick.Dialogs 1.3

    Dialog {
        title: "My Dialog"
        modality: Qt.ApplicationModal
        standardButtons: StandardButton.Ok | StandardButton.Cancel

        onAccepted: saveSettings()

        ColumnLayout {
            Label { text: "Content goes here" }
            TextField { id: nameField }
        }
    }
    \endcode

    After (ThemedDialog):
    \code
    ThemedDialog {
        title: "My Dialog"

        onAccepted: {
            saveSettings()
            close()
        }

        ColumnLayout {
            anchors.fill: parent
            Label { text: "Content goes here" }
            TextField { id: nameField }
        }
    }
    \endcode

    \section2 Key Differences from v1.3

    \list
    \li Content children need \c{anchors.fill: parent} to fill the content area.
    \li \c{standardButtons} is replaced by \c{showOkButton}, \c{showCancelButton},
        and the \c{leftButtons} property for additional buttons.
    \li The dialog does not auto-close on accept — call \c{close()} in your
        \c{onAccepted} handler. This gives you control for validation.
    \li Use \c{shake()} for validation feedback instead of message boxes.
    \li All colors come from the Compact theme and are user-configurable
        via the \c{[Theme]} section of the config file.
    \endlist

    \section2 Supported v1.3 Signals

    The following signals from QtQuick.Dialogs 1.3 are supported:
    \list
    \li \c{accepted()} — emitted when OK is clicked
    \li \c{rejected()} — emitted when Cancel or close button is clicked
    \li \c{reset()} — emitted when Restore Defaults is clicked (if enabled)
    \li \c{apply()} — emitted when Apply is clicked (if enabled)
    \li \c{help()} — emitted when Help is clicked (if enabled)
    \li \c{yes()} — emitted when Yes is clicked (if enabled)
    \li \c{no()} — emitted when No is clicked (if enabled)
    \endlist

    \section2 Additional Features

    \list
    \li \c{shake()} — shakes the dialog window for validation feedback
    \li \c{leftButtons} — custom buttons on the left side of the button bar
    \li \c{okEnabled} — enable/disable the OK button for validation
    \li Full dark theme with palette propagation to all child controls
    \li Centers on the main application window when opened
    \li Resizable with configurable minimum size
    \endlist
*/
Window {
    id: dialog

    flags: Qt.Dialog | Qt.WindowCloseButtonHint | Qt.WindowTitleHint
    modality: Qt.ApplicationModal
    color: Compact.dialogBackground

    width: 500
    height: 400
    minimumWidth: 300
    minimumHeight: 200

    // When the user clicks the OS window close button (×), treat as Cancel/Reject.
    // In v1.3, closing the dialog via the window manager triggers rejected().
    onClosing: {
        rejected();
    }

    // ── v1.3 Compatible Signals ──────────────────────────────────────
    // These match the signals from QtQuick.Dialogs 1.3 AbstractDialog
    // and Dialog types. Existing onAccepted/onRejected/etc. handlers
    // will work without changes.

    /*! Emitted when the OK button is clicked (AcceptRole).
        \note Unlike v1.3, the dialog does not auto-close.
        Call \c{close()} in your handler after processing.
        \sa rejected(), click() */
    signal accepted()

    /*! Emitted when the Cancel button or window close button is clicked (RejectRole).
        The dialog closes automatically after this signal.
        \sa accepted(), click() */
    signal rejected()

    /*! Emitted when Restore Defaults / Reset button is clicked (ResetRole).
        Only emitted if \c{showResetButton} is true.
        \sa showResetButton, click() */
    signal reset()

    /*! Emitted when the Apply button is clicked (ApplyRole).
        Only emitted if \c{showApplyButton} is true.
        \sa showApplyButton, click() */
    signal apply()

    /*! Emitted when the Discard button is clicked (DestructiveRole).
        Only emitted if \c{showDiscardButton} is true.
        \sa showDiscardButton, click() */
    signal discard()

    /*! Emitted when the Help button is clicked (HelpRole).
        Only emitted if \c{showHelpButton} is true.
        \sa showHelpButton, click() */
    signal help()

    /*! Emitted when the Yes button is clicked (YesRole).
        Only emitted if \c{showYesButton} is true.
        \sa showYesButton, no(), click() */
    signal yes()

    /*! Emitted when the No button is clicked (NoRole).
        Only emitted if \c{showNoButton} is true.
        \sa showNoButton, yes(), click() */
    signal no()

    /*! Emitted when any button is clicked, before the role-specific signal.
        Same as v1.3 Dialog.buttonClicked.
        \sa clickedButton */
    signal buttonClicked()

    /*! Emitted when any button is clicked or a key triggers a button action.
        The \a action parameter is an object with:
        \list
        \li \c{button} — the button identifier string ("ok", "cancel", etc.)
        \li \c{key} — the key code if triggered by keyboard, 0 otherwise
        \li \c{accepted} — set to false in your handler to prevent the action
        \endlist
        This is compatible with v1.3 Dialog.actionChosen.
        \sa click() */
    signal actionChosen(var action)

    // ── v1.3 Compatible Properties ───────────────────────────────────

    /*! The button that was last clicked. Matches v1.3 Dialog.clickedButton.
        Values: "ok", "cancel", "reset", "apply", "discard", "help", "yes", "no", or "".
        \sa buttonClicked */
    property string clickedButton: ""

    // ── v1.3 Compatible Properties ───────────────────────────────────

    /*! The default content area. Place your content as direct children
        of the ThemedDialog, just like QtQuick.Dialogs 1.3.
        Add \c{anchors.fill: parent} to your root layout. */
    default property alias contentData: contentArea.data

    // ── Button Visibility ────────────────────────────────────────────

    /*! Show the OK button (AcceptRole). Default: true.
        \sa okText, okEnabled, accepted() */
    property bool showOkButton: true

    /*! Show the Cancel button (RejectRole). Default: true.
        \sa cancelText, rejected() */
    property bool showCancelButton: true

    /*! Show the Restore Defaults / Reset button (ResetRole). Default: false.
        The button appears on the left side of the button bar.
        \sa resetText, reset() */
    property bool showResetButton: false

    /*! Show the Apply button (ApplyRole). Default: false.
        \sa applyText, apply() */
    property bool showApplyButton: false

    /*! Show the Help button (HelpRole). Default: false.
        The button appears on the left side of the button bar.
        \sa helpText, help() */
    property bool showHelpButton: false

    /*! Show the Yes button (YesRole). Default: false.
        \sa yesText, yes() */
    property bool showYesButton: false

    /*! Show the No button (NoRole). Default: false.
        \sa noText, no() */
    property bool showNoButton: false

    /*! Show the Discard button (DestructiveRole). Default: false.
        \sa discardText, discard() */
    property bool showDiscardButton: false

    // ── Button Text ──────────────────────────────────────────────────

    /*! Text for the OK button. Default: "OK". */
    property string okText: qsTr("OK")

    /*! Text for the Cancel button. Default: "Cancel". */
    property string cancelText: qsTr("Cancel")

    /*! Text for the Reset button. Default: "Restore Defaults". */
    property string resetText: qsTr("Restore Defaults")

    /*! Text for the Apply button. Default: "Apply". */
    property string applyText: qsTr("Apply")

    /*! Text for the Help button. Default: "Help". */
    property string helpText: qsTr("Help")

    /*! Text for the Yes button. Default: "Yes". */
    property string yesText: qsTr("Yes")

    /*! Text for the No button. Default: "No". */
    property string noText: qsTr("No")

    /*! Text for the Discard button. Default: "Discard". */
    property string discardText: qsTr("Discard")

    // ── Button State ─────────────────────────────────────────────────

    /*! Whether the OK button is enabled. Default: true.
        Set to false to prevent acceptance. Combine with \c{shake()}
        for user feedback when validation fails.
        \sa shake(), accepted() */
    property bool okEnabled: true

    // ── Extended Properties ──────────────────────────────────────────

    /*! Additional custom buttons placed on the left side of the button bar,
        after any standard left-side buttons (Reset, Help).

        Example:
        \code
        leftButtons: [
            Button {
                text: "Export..."
                onClicked: exportDialog.open()
            }
        ]
        \endcode
        \sa showResetButton, showHelpButton */
    property alias leftButtons: customLeftButtonArea.data

    // ── Methods ──────────────────────────────────────────────────────

    /*! Open the dialog centered on the main application window.
        Compatible with QtQuick.Dialogs 1.3 Dialog.open().
        \sa close() */
    function open() {
        x = rootWindow.x + Math.round((rootWindow.width - width) / 2);
        y = rootWindow.y + Math.round((rootWindow.height - height) / 2);
        dialog.show();
        dialog.raise();
        dialog.requestActivate();
    }

    /*! Programmatically trigger a button action by name.
        Compatible with v1.3 Dialog.click(StandardButton).

        Supported values: "ok", "cancel", "reset", "apply", "discard",
        "help", "yes", "no".

        Example:
        \code
        myDialog.click("ok")  // triggers accepted() signal
        \endcode
        \sa accepted(), rejected(), actionChosen() */
    function click(button) {
        var action = { "button": button, "key": 0, "accepted": true };
        actionChosen(action);
        if (!action.accepted) return;

        clickedButton = button;
        buttonClicked();

        switch (button) {
        case "ok":       accepted(); break;
        case "cancel":   rejected(); close(); break;
        case "reset":    reset(); break;
        case "apply":    apply(); break;
        case "discard":  discard(); break;
        case "help":     help(); break;
        case "yes":      yes(); close(); break;
        case "no":       no(); close(); break;
        }
    }

    /*! Shake the dialog window horizontally to indicate a validation error.
        Use this when the user clicks OK but validation prevents acceptance.

        Example:
        \code
        onAccepted: {
            if (!isValid()) {
                shake()
                return
            }
            saveData()
            close()
        }
        \endcode
        \sa okEnabled */
    function shake() {
        shakeAnimation.start();
    }

    // ── Private Implementation ───────────────────────────────────────

    SequentialAnimation {
        id: shakeAnimation

        property real restoreX: dialog.x

        loops: 2
        onStarted: restoreX = dialog.x
        PropertyAnimation { target: dialog; property: "x"; to: shakeAnimation.restoreX + 10; duration: 40; easing.type: Easing.OutQuad }
        PropertyAnimation { target: dialog; property: "x"; to: shakeAnimation.restoreX - 10; duration: 40; easing.type: Easing.OutQuad }
        PropertyAnimation { target: dialog; property: "x"; to: shakeAnimation.restoreX + 5; duration: 40; easing.type: Easing.OutQuad }
        PropertyAnimation { target: dialog; property: "x"; to: shakeAnimation.restoreX - 5; duration: 40; easing.type: Easing.OutQuad }
        PropertyAnimation { target: dialog; property: "x"; to: shakeAnimation.restoreX; duration: 40; easing.type: Easing.OutQuad }
    }

    // Keyboard handling — Enter/Return triggers OK, Escape triggers Cancel.
    // Matches v1.3 Dialog behavior.
    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (showOkButton && okEnabled) {
                    click("ok");
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Escape) {
                if (showCancelButton) {
                    click("cancel");
                } else {
                    dialog.close();
                }
                event.accepted = true;
            }
        }
    }

    // Theme Pane — propagates palette to all child controls.
    // (Window.palette is not available in Qt 5.12, but Pane.palette is.)
    Pane {
        anchors.fill: parent
        padding: 10

        palette.text: Compact.dialogText
        palette.windowText: Compact.dialogText
        palette.buttonText: Compact.dialogText
        palette.base: Compact.dialogInputBase
        palette.window: Compact.dialogBackground
        palette.button: Compact.dialogInputButton
        palette.mid: Compact.paletteMid
        palette.dark: Compact.paletteDark
        palette.highlight: Compact.accentColor
        palette.highlightedText: Compact.discoveryHighlightText

        background: Rectangle { color: Compact.dialogBackground }

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            // Content area — direct children of ThemedDialog go here
            Item {
                id: contentArea
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // Button bar separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Compact.paletteMid
                opacity: 0.3
            }

            // Button bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // ── Left-side standard buttons ───────────────────

                // Reset / Restore Defaults (left side, per platform convention)
                Loader {
                    active: showResetButton
                    sourceComponent: Component {
                        ThemedButton {
                            text: resetText
                            onClicked: dialog.click("reset")
                        }
                    }
                }

                // Help (left side)
                Loader {
                    active: showHelpButton
                    sourceComponent: Component {
                        ThemedButton {
                            text: helpText
                            onClicked: dialog.click("help")
                        }
                    }
                }

                // Custom left-side buttons
                Item {
                    id: customLeftButtonArea
                    implicitWidth: childrenRect.width
                    implicitHeight: childrenRect.height
                }

                Item { Layout.fillWidth: true }

                // ── Right-side standard buttons ──────────────────

                // Apply
                Loader {
                    active: showApplyButton
                    sourceComponent: Component {
                        ThemedButton {
                            text: applyText
                            onClicked: dialog.click("apply")
                        }
                    }
                }

                // Discard (DestructiveRole)
                Loader {
                    active: showDiscardButton
                    sourceComponent: Component {
                        ThemedButton {
                            text: discardText
                            destructive: true
                            onClicked: dialog.click("discard")
                        }
                    }
                }

                // No
                Loader {
                    active: showNoButton
                    sourceComponent: Component {
                        ThemedButton {
                            text: noText
                            onClicked: dialog.click("no")
                        }
                    }
                }

                // Yes
                Loader {
                    active: showYesButton
                    sourceComponent: Component {
                        ThemedButton {
                            text: yesText
                            accent: true
                            onClicked: dialog.click("yes")
                        }
                    }
                }

                // Cancel
                ThemedButton {
                    visible: showCancelButton
                    text: cancelText
                    onClicked: dialog.click("cancel")
                }

                // OK
                ThemedButton {
                    visible: showOkButton
                    text: okText
                    accent: true
                    enabled: okEnabled
                    onClicked: dialog.click("ok")
                }
            }
        }
    }
}
