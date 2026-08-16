// DashboardWidget.qml --- rigid box layout; flex children minHeight=0 so nothing overflows
import QtQuick
import QtQuick.Layouts
import "../.."
import "Dashboard"

Item {
    id: root
    // StackLayout sizes us to the stack host — never size from content
    clip: true

    readonly property int colGap: Tokens.spacingSm
    readonly property int gutter: Tokens.paddingH

    RowLayout {
        id: mainRow
        anchors.fill: parent
        anchors.margins: root.gutter
        spacing: Tokens.spacingMd

        // ---- LEFT ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            Layout.minimumWidth: 0
            Layout.maximumWidth: parent.width
            spacing: root.colGap

            TimeCard {
                Layout.fillWidth: true
                Layout.maximumHeight: implicitHeight
            }

            MissionTimerCard {
                Layout.fillWidth: true
                Layout.maximumHeight: implicitHeight
            }

            CalendarCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 1
                Layout.minimumHeight: 0
            }
        }

        // ---- MID ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            Layout.minimumWidth: 0
            spacing: root.colGap

            TodoCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 1
                Layout.minimumHeight: 0
            }

            NotesCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 1
                Layout.minimumHeight: 0
            }
        }

        // ---- RIGHT ----
        // Fixed strip (disk|net + uptime) + flex (weather, patches).
        // All flex items: minimumHeight 0 so the column can never exceed parent.
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            Layout.minimumWidth: 0
            spacing: root.colGap

            WeatherCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 3
                Layout.minimumHeight: 0
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Tokens.diskNetCardHeight
                Layout.minimumHeight: Tokens.diskNetCardHeight
                Layout.maximumHeight: Tokens.diskNetCardHeight
                spacing: root.colGap

                DiskCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                }

                NetCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                }
            }

            UpdatesCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 1
                Layout.minimumHeight: 0
            }

            UptimeCard {
                Layout.fillWidth: true
                Layout.maximumHeight: implicitHeight
            }
        }
    }
}
