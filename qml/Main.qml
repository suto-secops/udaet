import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: root

    title: qsTr("Udaet")
    width: 1000
    height: 700
    visible: true

    globalDrawer: Kirigami.GlobalDrawer {
        title: qsTr("Udaet")
        titleIcon: "journal"
        modal: false

        actions: [
            Kirigami.Action {
                text: qsTr("Diary")
                icon.name: "journal"
                onTriggered: diaryStore.loadToday()
            },
            Kirigami.Action {
                text: qsTr("Calendar")
                icon.name: "view-calendar"
                enabled: false
            },
            Kirigami.Action {
                text: qsTr("Trends")
                icon.name: "office-chart-line"
                enabled: false
            }
        ]
    }

    pageStack.initialPage: Kirigami.ScrollablePage {
        title: qsTr("Diary - %1").arg(diaryStore.currentDate)

        Column {
            width: parent.width
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Heading {
                text: qsTr("What made today meaningful?")
                level: 2
            }

            Row {
                width: parent.width
                spacing: Kirigami.Units.smallSpacing

                Controls.TextField {
                    id: dateField
                    width: parent.width - loadDateButton.width - Kirigami.Units.smallSpacing
                    text: diaryStore.currentDate
                    placeholderText: qsTr("YYYY-MM-DD")
                    inputMethodHints: Qt.ImhDate
                }

                Controls.Button {
                    id: loadDateButton
                    text: qsTr("Load date")
                    onClicked: diaryStore.loadDay(dateField.text)
                }
            }

            Controls.Label {
                text: qsTr("Markdown source")
                opacity: 0.8
            }

            Row {
                width: parent.width
                spacing: Kirigami.Units.largeSpacing

                Column {
                    width: (parent.width - parent.spacing) / 2
                    spacing: Kirigami.Units.smallSpacing

                    Controls.Label {
                        text: qsTr("Source")
                        font.bold: true
                    }

                    Controls.TextArea {
                        id: entryEditor
                        width: parent.width
                        implicitHeight: Kirigami.Units.gridUnit * 12
                        placeholderText: qsTr("Write Markdown about your day...")
                        text: diaryStore.entryText
                        onTextChanged: if (activeFocus) diaryStore.entryText = text
                        wrapMode: Controls.TextArea.Wrap
                    }
                }

                Column {
                    width: (parent.width - parent.spacing) / 2
                    spacing: Kirigami.Units.smallSpacing

                    Controls.Label {
                        text: qsTr("Preview")
                        font.bold: true
                    }

                    Controls.ScrollView {
                        id: previewScroll
                        width: parent.width
                        height: entryEditor.implicitHeight
                        contentWidth: availableWidth

                        Controls.Label {
                            width: previewScroll.availableWidth
                            text: diaryStore.entryText.length > 0
                                ? diaryStore.entryText
                                : qsTr("Rendered preview will appear here.")
                            textFormat: Text.MarkdownText
                            wrapMode: Controls.Label.Wrap
                        }
                    }
                }
            }

            Kirigami.Separator {
                width: parent.width
            }

            Controls.Label {
                text: diaryStore.rated
                    ? qsTr("Eudaimonia rating (optional): %1 / 10").arg(diaryStore.rating.toFixed(2))
                    : qsTr("Eudaimonia rating (optional): Not rated")
                opacity: 0.8
            }

            Row {
                width: parent.width
                spacing: Kirigami.Units.largeSpacing

                Controls.TextField {
                    id: ratingField
                    width: Kirigami.Units.gridUnit * 6
                    text: diaryStore.ratingText
                    placeholderText: qsTr("0.00 - 10.00")
                    validator: DoubleValidator {
                        bottom: 0
                        top: 10
                        decimals: 2
                    }
                    onEditingFinished: {
                        if (!diaryStore.setRatingText(text)) {
                            text = diaryStore.ratingText
                        }
                    }
                }

                Controls.Slider {
                    id: ratingSlider
                    width: parent.width - ratingField.width - clearRatingButton.width - (parent.spacing * 2)
                    from: 0
                    to: 10
                    stepSize: 0.01
                    value: diaryStore.rated ? diaryStore.rating : 0
                    onMoved: diaryStore.rating = value
                }

                Controls.Button {
                    id: clearRatingButton
                    text: qsTr("Clear")
                    enabled: diaryStore.rated
                    onClicked: diaryStore.clearRating()
                }
            }

            Row {
                spacing: Kirigami.Units.smallSpacing

                Controls.Button {
                    text: qsTr("Save")
                    icon.name: "document-save"
                    onClicked: diaryStore.saveCurrentDay()
                }
            }

            Controls.Label {
                visible: diaryStore.errorMessage.length > 0
                text: diaryStore.errorMessage
                color: Kirigami.Theme.negativeTextColor
                wrapMode: Controls.Label.Wrap
            }
        }
    }
}
