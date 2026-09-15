import qs.modules.common
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

MaterialShape { // App icon
    id: root
    property var appIcon: ""
    property var summary: ""
    property var body: ""
    property var urgency: NotificationUrgency.Normal
    property bool isUrgent: urgency === NotificationUrgency.Critical
    property var image: ""
    property var notificationBodies: []
    property real materialIconScale: 0.57
    property real appIconScale: 0.8
    property real smallAppIconScale: 0.49
    property real materialIconSize: implicitSize * materialIconScale
    property real appIconSize: implicitSize * appIconScale
    property real smallAppIconSize: implicitSize * smallAppIconScale

    function lowerBodies() {
      return notificationBodies.length > 0
      ? notificationBodies.map(b => (b || "").toLowerCase())
      : [body?.toLowerCase() || ""]
    }

    property bool isTwitchNotification: lowerBodies().length > 0 && lowerBodies().every(b => b.includes("from twitch"))
    property bool isKickNotification: lowerBodies().length > 0 && lowerBodies().every(b => b.includes("from kick"))
    // kick-live-watcher sends the bundled kick.svg via the image-path hint
    // directly (not the "from kick" body-text isKickNotification above was
    // written for), identified the same way as elsewhere in this file:
    // Quickshell resolves image-path hints through the image://icon/
    // provider, so root.image looks like "image://icon//abs/path/kick.svg"
    // rather than a plain path — match by suffix, not equality.
    readonly property bool isKickImageAsset: root.image.toString().endsWith("assets/icons/kick.svg")

    implicitSize: 38 * scale
    property list<var> urgentShapes: [
        MaterialShape.Shape.VerySunny,
        MaterialShape.Shape.SoftBurst,
    ]
    shape: isUrgent ? urgentShapes[Math.floor(Math.random() * urgentShapes.length)] : MaterialShape.Shape.Circle

    color: isUrgent ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSecondaryContainer
    Loader {
        id: materialSymbolLoader
        // Twitch/Kick notifications often carry no appIcon/image hint at
        // all (e.g. a plain Betterbird "from Twitch" text notification) —
        // without this exclusion this Loader and appIconLoader below were
        // BOTH active simultaneously and painted on top of each other.
        active: root.appIcon == "" && root.image == "" && !root.isTwitchNotification && !root.isKickImageAsset
        anchors.fill: parent
        sourceComponent: MaterialSymbol {
            text: {
                const defaultIcon = NotificationUtils.findSuitableMaterialSymbol("")
                const guessedIcon = NotificationUtils.findSuitableMaterialSymbol(root.summary)
                return (root.urgency == NotificationUrgency.Critical && guessedIcon === defaultIcon) ?
                    "priority_high" : guessedIcon
            }
            anchors.fill: parent
            color: isUrgent ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer
            iconSize: root.materialIconSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
    Loader {
        id: appIconLoader
        // Twitch/Kick get routed here (a small badge icon) instead of
        // notifImageLoader below (a big cropped photo) — neither has a
        // proper image of their own to crop that way, just a logo.
        active: root.isTwitchNotification || root.isKickImageAsset || (root.image == "" && root.appIcon != "")
        anchors.centerIn: parent
        sourceComponent: IconImage {
            id: appIconImage
            implicitSize: root.appIconSize
            asynchronous: false
            // Betterbird's own notification for a "from Twitch" email
            // carries its own (mail-client) appIcon, not a Twitch one —
            // override it. Neither Twitch nor Kick have a logo in the
            // installed icon theme we're happy with, so both are bundled
            // assets (recolored into DynamicTheme by
            // recolor_notif_svg_assets() in recolor_icons.py) instead of a
            // theme-name lookup.
            source: root.isTwitchNotification
                ? (Config.options.appearance.icons.enableThemed
                    ? `${Directories.home}/.local/share/icons/DynamicTheme/notif-images/vynx-notif-twitch.svg`
                    : Quickshell.shellPath("assets/icons/twitch.svg"))
                : root.isKickImageAsset
                ? (Config.options.appearance.icons.enableThemed
                    ? `${Directories.home}/.local/share/icons/DynamicTheme/notif-images/vynx-notif-kick.svg`
                    : Quickshell.shellPath("assets/icons/kick.svg"))
                : Quickshell.iconPath(root.appIcon, "image-missing")
        }
    }
    Loader {
        id: notifImageLoader
        // Excludes our own Kick asset — that's handled by appIconLoader
        // above instead (see isKickImageAsset).
        active: root.image != "" && !root.isKickImageAsset
        anchors.fill: parent
        sourceComponent: Item {
            anchors.fill: parent
            StyledImage {
                id: notifImage
                anchors.fill: parent
                readonly property int size: parent.width

                source: root.image
                fillMode: Image.PreserveAspectCrop
                cache: true
                antialiasing: true
                asynchronous: !source.toString().startsWith("image://icon/")

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: notifImage.size
                        height: notifImage.size
                        radius: Appearance.rounding.full
                    }
                }
            }
            Loader {
                id: notifImageAppIconLoader
                active: root.appIcon != ""
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                sourceComponent: IconImage {
                    implicitSize: root.smallAppIconSize
                    asynchronous: false
                    source: Quickshell.iconPath(root.appIcon, "image-missing")
                }
            }
        }
    }
}
