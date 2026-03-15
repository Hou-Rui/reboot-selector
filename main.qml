pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import Backend

Kirigami.ApplicationWindow {
    id: root
    width: 580
    height: 520
    visible: true

    BootModel {
        id: bootModel
        onMessageChanged: banner.visible = !!message.type
    }

    pageStack.initialPage: Kirigami.ScrollablePage {
        title: qsTr("Boot Entries")

        actions: [
            Kirigami.Action {
                icon.name: "reload"
                text: qsTr("Reload")
                onTriggered: bootModel.reload()
            },
            Kirigami.Action {
                icon.name: "system-reboot-update"
                text: qsTr("Reboot Now")
                onTriggered: bootModel.rebootNow()
            }
        ]

        header: Kirigami.InlineMessage {
            id: banner
            position: Kirigami.InlineMessage.Position.Header
            showCloseButton: bootModel.message.type !== "error"
            type: {
                switch (bootModel.message.type) {
                case "error":
                    return Kirigami.MessageType.Error;
                case "positive":
                    return Kirigami.MessageType.Positive;
                default:
                    return Kirigami.MessageType.Information;
                }
            }
            text: bootModel.message.text
            visible: !!bootModel.message.type
        }

        Kirigami.CardsListView {
            model: bootModel.entries

            delegate: Kirigami.AbstractCard {
                id: card
                required property var modelData
                headerOrientation: Qt.Horizontal
                
                contentItem: Item {
                    implicitWidth: delegateLayout.implicitWidth
                    implicitHeight: delegateLayout.implicitHeight
            
                    RowLayout {
                        id: delegateLayout
                        anchors {
                            left: parent.left
                            top: parent.top
                            right: parent.right
                        }
                        
                        Kirigami.Icon {
                            source: {
                                if (card.modelData.id.includes("windows"))
                                    return "windows";
                                if (card.modelData.id.includes("linux"))
                                    return "preferences-system-linux";
                                return "preferences-system-disks";
                            }
                        }
                        
                        Label {
                            Layout.fillWidth: true
                            text: card.modelData.title
                            wrapMode: Text.WordWrap
                        }
                        
                        EntryChip {
                            visible: card.modelData.isSelected
                            text: qsTr("Default")
                        }
                        
                        EntryChip {
                            visible: card.modelData.isDefault
                            text: qsTr("Next Boot")
                        }
                        
                        ToolSeparator {
                            
                        }
                        
                        Button {
                            icon.name: "object-select-symbolic"
                            text: qsTr("Select Next Boot")
                            enabled: !card.modelData.isDefault
                            onClicked: bootModel.setOneShot(card.modelData.id)
                        }
                    }
                }
            }
        }
    }
    
    component EntryChip: Kirigami.Chip {
        closable: false
        interactive: false
        font.bold: true
    }
}
