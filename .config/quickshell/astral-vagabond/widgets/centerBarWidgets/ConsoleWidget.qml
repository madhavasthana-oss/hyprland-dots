// ConsoleWidget.qml --- system app / applet launcher (DesktopEntries)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../.."
import "../../utils"
import "console"

Item {
    id: root
    clip: true

    property int selectedIndex: 0

    ConsoleModel { id: catalog }

    function selectIndex(i) {
        if (catalog.model.count <= 0) {
            selectedIndex = 0
            return
        }
        const next = Math.max(0, Math.min(catalog.model.count - 1, i))
        selectedIndex = next
        if (appList.currentIndex !== next)
            appList.currentIndex = next
        appList.positionViewAtIndex(next, ListView.Contain)
    }

    function launchSelected() {
        if (catalog.launchIndex(selectedIndex))
            Globals.closeWidget()
    }

    function iconSource(name) {
        const p = Quickshell.iconPath(name, true)
        return p && p.length ? p : ""
    }

    function grabListFocus() {
        searchInput.forceActiveFocus()
    }

    function grabConsoleFocus() {
        grabListFocus()
    }

    Component.onCompleted: {
        catalog.rebuild()
        selectIndex(0)
        if (Globals.activeWidget === "console")
            grabConsoleFocus()
    }

    Connections {
        target: Globals
        function onActiveWidgetChanged() {
            if (Globals.activeWidget === "console")
                Qt.callLater(root.grabConsoleFocus)
        }
    }

    Connections {
        target: catalog.model
        function onCountChanged() {
            if (catalog.model.count === 0) {
                selectedIndex = 0
                return
            }
            if (selectedIndex >= catalog.model.count)
                selectIndex(catalog.model.count - 1)
            else
                selectIndex(selectedIndex)
        }
    }

    focus: true
    Keys.forwardTo: [searchInput, appList]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.paddingH
        spacing: Tokens.spacingXs

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacingXs

            Text {
                text: "APPS"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.accent
            }

            Item { Layout.fillWidth: true }

            Text {
                text: catalog.matchCount + (catalog.query.length ? " MATCH" : " ON DEVICE")
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeTiny
                color: Theme.textSecondary
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Tokens.listRowHeight + Tokens.paddingV
            radius: Tokens.radiusSm
            color: Theme.bgElevated
            border.color: searchInput.activeFocus ? Theme.borderActive : Theme.borderIdle
            border.width: Tokens.strokeWidth

            TextInput {
                id: searchInput
                anchors.fill: parent
                anchors.leftMargin: Tokens.paddingH
                anchors.rightMargin: Tokens.paddingH
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.textPrimary
                selectedTextColor: Theme.bgPrimary
                selectionColor: Theme.accent
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeSmall
                clip: true
                focus: true
                onTextChanged: {
                    catalog.query = text
                    root.selectIndex(0)
                }
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.launchSelected()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down) {
                        root.selectIndex(root.selectedIndex + 1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up) {
                        root.selectIndex(root.selectedIndex - 1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape) {
                        if (searchInput.text.length) {
                            searchInput.text = ""
                            event.accepted = true
                        }
                    }
                }
            }

            Text {
                anchors.fill: parent
                anchors.leftMargin: Tokens.paddingH
                verticalAlignment: Text.AlignVCenter
                visible: searchInput.text.length === 0
                enabled: false
                text: "search apps & applets"
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeSmall
                color: Theme.textDim
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            Layout.minimumHeight: 0
            radius: Tokens.radiusMd
            color: Theme.bgSurface
            border.color: Theme.borderIdle
            border.width: Tokens.strokeWidth
            clip: true

            ListView {
                id: appList
                anchors.fill: parent
                anchors.margins: Tokens.paddingH
                clip: true
                implicitWidth: 0
                spacing: Tokens.spacingXss
                model: catalog.model
                currentIndex: root.selectedIndex
                focus: true
                activeFocusOnTab: true
                keyNavigationEnabled: false
                highlightFollowsCurrentItem: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                interactive: contentHeight > height
                ScrollBar.vertical: MonoScrollBar {}

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.launchSelected()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up) {
                        root.selectIndex(root.selectedIndex - 1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down) {
                        root.selectIndex(root.selectedIndex + 1)
                        event.accepted = true
                    } else if (event.text && event.text.length && event.text[0] >= " ") {
                        searchInput.forceActiveFocus()
                        searchInput.text += event.text
                        event.accepted = true
                    }
                }

                delegate: Rectangle {
                    width: Math.max(0, appList.width
                        - (appList.contentHeight > appList.height
                            ? Tokens.borderXs + Tokens.spacingXss + 2
                            : 0))
                    height: Math.max(Tokens.statBoxHeight, rowCol.implicitHeight + Tokens.paddingV)
                    radius: Tokens.radiusSm
                    color: index === root.selectedIndex ? Theme.bgElevated : "transparent"
                    border.color: index === root.selectedIndex ? Theme.borderActive : "transparent"
                    border.width: Tokens.strokeWidth

                    RowLayout {
                        id: rowCol
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.paddingH
                        anchors.rightMargin: Tokens.paddingH
                        spacing: Tokens.spacingXs

                        Image {
                            Layout.preferredWidth: Tokens.iconSizeLarge
                            Layout.preferredHeight: Tokens.iconSizeLarge
                            source: root.iconSource(model.icon)
                            sourceSize: Qt.size(Tokens.iconSizeLarge * 2, Tokens.iconSizeLarge * 2)
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: model.title
                                font.family: Theme.fontDisplay
                                font.pixelSize: Tokens.fontSizeLabel
                                color: index === root.selectedIndex ? Theme.accent : Theme.textPrimary
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: (model.classification && model.classification.length)
                                    || (model.description && model.description.length)
                                text: {
                                    const a = model.classification || ""
                                    const b = model.description || ""
                                    if (a.length && b.length)
                                        return a + " · " + b
                                    return a.length ? a : b
                                }
                                font.family: Theme.fontMono
                                font.pixelSize: Tokens.fontSizeTiny
                                color: Theme.textSecondary
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectIndex(index)
                            appList.forceActiveFocus()
                        }
                        onDoubleClicked: {
                            root.selectIndex(index)
                            root.launchSelected()
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: appList.count === 0
                    text: catalog.query.length ? "NO MATCH" : "NO APPS"
                    font.family: Theme.fontDisplay
                    font.pixelSize: Tokens.fontSizeLabel
                    color: Theme.textDim
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "TYPE to filter * ENTER launch * ESC close"
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeTiny
            color: Theme.textDim
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
