pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.formcard as FormCard

import Backend

Kirigami.ApplicationWindow {
    id: root
    width: 520
    height: 420
    visible: true

    BootModel {
        id: bootModel
        onErrorOccurred: message => {
            banner.type = Kirigami.MessageType.Error;
            banner.text = message;
            banner.visible = true;
        }
        onSuccessOccurred: message => {
            banner.type = Kirigami.MessageType.Information;
            banner.text = message;
            banner.visible = true;
        }
    }

    pageStack.initialPage: FormCard.FormCardPage {
        title: qsTr("Boot Entries")

        actions: [
            Kirigami.Action {
                icon.name: "reload"
                text: qsTr("Reload")
                onTriggered: bootModel.reload()
            }
        ]

        header: Kirigami.InlineMessage {
            id: banner
            position: Kirigami.InlineMessage.Position.Header
            showCloseButton: true
        }

        FormCard.FormHeader {
            title: qsTr("Select next reboot OS: ")
        }

        FormCard.FormCard {
            Repeater {
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
        }
    }
}
