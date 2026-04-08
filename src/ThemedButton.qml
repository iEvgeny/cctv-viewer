import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Templates 2.12 as T
import CCTV_Viewer.Themes 1.0

/*!
    \qmltype ThemedButton
    \brief A dark-themed button for use inside ThemedDialog.

    ThemedButton provides consistent button styling that matches ThemedDialog's
    dark theme. It eliminates the need to manually override \c{background} and
    \c{contentItem} on every Button inside a dialog.

    \section1 Button Variants

    \table
    \header \li Property \li Visual Style \li Use Case
    \row \li (default) \li Dark background, light text, mid border \li Standard actions (Clear, Cancel)
    \row \li \c{accent: true} \li Accent (teal) background, white text \li Primary actions (OK, Yes, Save)
    \row \li \c{destructive: true} \li Red background, white text \li Dangerous actions (Discard, Delete)
    \row \li \c{active: true} \li Accent background (dynamic) \li Toggled state (key capture active)
    \endtable

    \section1 Examples

    Standard button:
    \code
    ThemedButton {
        text: "Clear"
        onClicked: clearField()
    }
    \endcode

    Accent (primary action) button:
    \code
    ThemedButton {
        text: "Save"
        accent: true
        onClicked: save()
    }
    \endcode

    Destructive button:
    \code
    ThemedButton {
        text: "Delete"
        destructive: true
        onClicked: confirmDelete()
    }
    \endcode

    Dynamic active state (e.g. key capture):
    \code
    ThemedButton {
        text: capturing ? "Press key..." : binding
        active: capturing
        onClicked: startCapture()
    }
    \endcode
*/
T.Button {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: Compact.buttonPadding
    horizontalPadding: padding + 2
    spacing: Compact.spacing

    /*! When true, the button uses accent color (teal) for primary actions.
        \sa destructive, active */
    property bool accent: false

    /*! When true, the button uses destructive color (red) for dangerous actions.
        Takes precedence over \c{accent}.
        \sa accent */
    property bool destructive: false

    /*! When true, the button uses accent color to indicate an active/toggled state.
        Unlike \c{accent}, this is intended for dynamic toggling (e.g. key capture mode).
        \sa accent */
    property bool active: false

    // ── Computed base color ──────────────────────────────────────────
    readonly property color __baseColor: {
        if (!control.enabled) return Qt.darker(Compact.paletteDark, 1.2);
        if (destructive)      return Compact.dialogDestructive;
        if (accent || active) return Compact.accentColor;
        return Qt.lighter(Compact.paletteDark, 1.5);
    }

    readonly property color __pressedColor: {
        if (destructive)      return Qt.darker(Compact.dialogDestructive, 1.2);
        if (accent || active) return Qt.darker(Compact.accentColor, 1.2);
        return Qt.darker(Compact.paletteMid, 1.3);
    }

    readonly property color __hoverColor: {
        if (destructive)      return Qt.lighter(Compact.dialogDestructive, 1.2);
        if (accent || active) return Qt.lighter(Compact.accentColor, 1.2);
        return Compact.paletteMid;
    }

    readonly property color __borderColor: {
        if (!control.enabled) return Compact.paletteMid;
        if (destructive)      return Compact.dialogDestructive;
        if (accent || active) return Compact.accentColor;
        return Compact.paletteMid;
    }

    readonly property color __textColor: {
        if (!control.enabled)                   return Compact.paletteMid;
        if (accent || active || destructive)    return Compact.discoveryHighlightText;
        return Compact.sidebarText;
    }

    background: Rectangle {
        radius: Compact.radius
        implicitWidth: 100
        implicitHeight: 40
        color: control.down ? control.__pressedColor
             : control.hovered ? control.__hoverColor
             : control.__baseColor
        border.color: control.__borderColor
        border.width: 1
    }

    contentItem: Text {
        text: control.text
        font: control.font
        color: control.__textColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
