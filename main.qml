pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

import Backend

Kirigami.ApplicationWindow {
    id: root
    width: 450
    height: 420
    visible: true

    BootModel {
        id: bootModel
        onMessageChanged: banner.visible = !!message.type
    }

    pageStack.initialPage: FormCard.FormCardPage {
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

        FormCard.FormHeader {
            title: qsTr("Select next reboot OS: ")
        }

        FormCard.FormCard {
            Repeater {
                id: entriesRepeater
                model: bootModel.entries

                FormCard.FormButtonDelegate {
                    required property var modelData
                    text: modelData.title
                    description: {
                        let tags = [];
                        if (modelData.isSelected)
                            tags.push(qsTr("Default OS"));
                        if (modelData.isDefault)
                            tags.push(qsTr("Next Reboot OS"));
                        return tags.join(", ");
                    }

                    icon.name: {
                        if (modelData.id.includes("windows"))
                            return "windows";
                        if (modelData.id.includes("linux"))
                            return "preferences-system-linux";
                        return "preferences-system-disks";
                    }

                    onClicked: bootModel.setOneShot(modelData.id)
                }
            }

            FormCard.FormPlaceholderMessageDelegate {
                text: qsTr("No boot entries detected")
                visible: entriesRepeater.count === 0
            }
        }
    }
}
