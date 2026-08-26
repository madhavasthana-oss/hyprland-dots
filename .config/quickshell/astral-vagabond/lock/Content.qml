import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
    id: root

    required property var lock

    spacing: Tokens.spacingXl

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Tokens.spacingMd

        WeatherInfo {
            Layout.fillWidth: true
            rootHeight: root.height
        }

        Fetch {
            Layout.fillWidth: true
            rootHeight: root.height
        }

        Media {
            Layout.fillWidth: true
            Layout.fillHeight: true
            lock: root.lock
        }
    }

    Center {
        lock: root.lock
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Tokens.spacingMd

        Resources {
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Tokens.radiusMd
            color: Theme.bgSurface
            border.color: Theme.borderIdle
            border.width: Tokens.strokeWidth
            clip: true

            NotifDock {
                anchors.fill: parent
                lock: root.lock
            }
        }
    }
}
