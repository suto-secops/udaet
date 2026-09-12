import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: root

    title: qsTr("Udaet")
    width: 1000
    height: 700
    visible: true

    function showDiary(date) {
        if (date.length > 0) {
            diaryStore.loadDay(date)
        } else {
            diaryStore.loadToday()
        }
        pageStack.replace(diaryPage)
    }

    function showCalendar() {
        pageStack.replace(calendarPage)
    }

    globalDrawer: Kirigami.GlobalDrawer {
        id: navigationDrawer
        title: qsTr("Udaet")
        titleIcon: "journal-new"
        modal: false

        actions: [
            Kirigami.Action {
                text: qsTr("Diary")
                icon.name: "journal-new"
                onTriggered: root.showDiary("")
            },
            Kirigami.Action {
                text: qsTr("Calendar")
                icon.name: "view-calendar"
                onTriggered: root.showCalendar()
            },
            Kirigami.Action {
                text: qsTr("Trends")
                icon.name: "office-chart-line"
                enabled: false
            },
            Kirigami.Action {
                text: qsTr("Close navigation")
                icon.name: "sidebar-collapse"
                onTriggered: navigationDrawer.close()
            }
        ]
    }

    pageStack.initialPage: diaryPage

    Component {
        id: diaryPage

        Kirigami.ScrollablePage {
            title: qsTr("Diary: %1").arg(diaryStore.currentDate)
            actions: Kirigami.Action {
                text: qsTr("Navigation")
                icon.name: navigationDrawer.opened ? "sidebar-collapse" : "sidebar-expand"
                onTriggered: {
                    if (navigationDrawer.opened) {
                        navigationDrawer.close()
                    } else {
                        navigationDrawer.open()
                    }
                }
            }

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

                        Controls.Label {
                            visible: diaryStore.hardBreakCount > 0
                            width: parent.width
                            text: qsTr("%1 Markdown hard break(s): trailing spaces before a newline are active.")
                                .arg(diaryStore.hardBreakCount)
                            color: Kirigami.Theme.neutralTextColor
                            wrapMode: Controls.Label.Wrap
                        }

                        Controls.Label {
                            visible: diaryStore.hardBreakCount > 0
                            width: parent.width
                            text: qsTr("Whitespace guide: %1").arg(diaryStore.hardBreakGuide)
                            font.family: "monospace"
                            opacity: 0.75
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

                Kirigami.Separator { width: parent.width }

                Controls.Label {
                    text: diaryStore.rated
                        ? qsTr("Eudaimonia rating (optional): %1 / 10").arg(diaryStore.ratingText)
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
                        validator: DoubleValidator { bottom: 0; top: 10; decimals: 2 }
                        onEditingFinished: if (!diaryStore.setRatingText(text)) text = diaryStore.ratingText
                    }

                    Controls.Slider {
                        id: ratingSlider
                        width: parent.width - ratingField.width - clearRatingButton.width - (parent.spacing * 2)
                        from: 0; to: 10; stepSize: 0.01
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

                Controls.Button {
                    text: qsTr("Save")
                    icon.name: "document-save"
                    onClicked: diaryStore.saveCurrentDay()
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

    Component {
        id: calendarPage

        Kirigami.ScrollablePage {
            id: calendar
            property int shownYear: new Date().getFullYear()
            property int shownMonth: new Date().getMonth() + 1
            property var filledDays: []
            title: qsTr("Calendar")
            actions: Kirigami.Action {
                text: qsTr("Navigation")
                icon.name: navigationDrawer.opened ? "sidebar-collapse" : "sidebar-expand"
                onTriggered: {
                    if (navigationDrawer.opened) {
                        navigationDrawer.close()
                    } else {
                        navigationDrawer.open()
                    }
                }
            }

            function refresh() {
                filledDays = diaryStore.daysWithContent(shownYear, shownMonth)
            }
            function isFilled(day) {
                return filledDays.indexOf("%1-%2-%3".arg(shownYear)
                    .arg(("0" + shownMonth).slice(-2))
                    .arg(("0" + day).slice(-2))) >= 0
            }
            function monthName() {
                return new Date(shownYear, shownMonth - 1, 1).toLocaleString(
                    Qt.locale(), "MMMM yyyy")
            }
            function previousMonth() {
                if (--shownMonth < 1) { shownMonth = 12; --shownYear }
                refresh()
            }
            function nextMonth() {
                if (++shownMonth > 12) { shownMonth = 1; ++shownYear }
                refresh()
            }
            Component.onCompleted: refresh()

            Column {
                width: parent.width
                spacing: Kirigami.Units.largeSpacing

                Row {
                    width: parent.width
                    Controls.Button {
                        id: previousButton
                        text: qsTr("Previous")
                        onClicked: calendar.previousMonth()
                    }
                    Controls.Label {
                        width: parent.width - previousButton.width - nextButton.width
                        id: monthTitle
                        text: calendar.monthName()
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                    }
                    Controls.Button {
                        id: nextButton
                        text: qsTr("Next")
                        onClicked: calendar.nextMonth()
                    }
                }

                Controls.Label {
                    text: qsTr("Filled days are highlighted. Select a day to open it.")
                    opacity: 0.8
                }

                Grid {
                    id: monthGrid
                    width: parent.width
                    columns: 7
                    spacing: Kirigami.Units.smallSpacing
                    Repeater {
                        model: 42
                        delegate: Controls.Button {
                            required property int index
                            property int firstWeekday: new Date(calendar.shownYear, calendar.shownMonth - 1, 1).getDay()
                            property int dayNumber: index - firstWeekday + 1
                            visible: dayNumber > 0 && dayNumber <= new Date(calendar.shownYear, calendar.shownMonth, 0).getDate()
                            width: (monthGrid.width - monthGrid.spacing * 6) / 7
                            text: visible ? dayNumber : ""
                            highlighted: visible && calendar.isFilled(dayNumber)
                            onClicked: root.showDiary("%1-%2-%3".arg(calendar.shownYear)
                                .arg(("0" + calendar.shownMonth).slice(-2))
                                .arg(("0" + dayNumber).slice(-2)))
                        }
                    }
                }
            }
        }
    }
}
