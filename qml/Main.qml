import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
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

    function showSettings() {
        pageStack.replace(settingsPage)
    }

    globalDrawer: Kirigami.GlobalDrawer {
        id: navigationDrawer
        title: ""
        titleIcon: null
        modal: false
        interactiveResizeEnabled: true

        topContent: [
            Column {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Rectangle {
                    width: parent.width
                    height: Kirigami.Units.gridUnit * 2
                    color: "transparent"
                    border.color: Kirigami.Theme.separatorColor
                    radius: Kirigami.Units.smallSpacing

                    Controls.Button {
                        anchors.fill: parent
                        flat: true
                        onClicked: navigationDrawer.close()

                        contentItem: RowLayout {
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                source: "sidebar-collapse"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            }

                            Controls.Label {
                                text: qsTr("Close sidebar")
                                Layout.fillWidth: true
                                elide: Text.ElideNone
                                horizontalAlignment: Text.AlignLeft
                            }
                        }
                    }
                }

                Kirigami.Separator {
                    width: parent.width
                }

                Controls.Label {
                    leftPadding: Kirigami.Units.smallSpacing
                    text: qsTr("Navigation")
                    font.bold: true
                    opacity: 0.8
                }
            }
        ]

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
                separator: true
            },
            Kirigami.Action {
                text: qsTr("Other")
                enabled: false
            },
            Kirigami.Action {
                text: qsTr("Settings")
                icon.name: "configure"
                onTriggered: root.showSettings()
            }
        ]
    }

    pageStack.initialPage: diaryPage

    Component {
        id: diaryPage

        Kirigami.ScrollablePage {
            title: qsTr("Diary: %1").arg(diaryStore.currentDate)

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

                        Rectangle {
                            width: parent.width
                            height: entryEditor.implicitHeight
                            color: "transparent"
                            border.width: 1
                            border.color: entryEditor.palette.midlight
                            radius: Kirigami.Units.smallSpacing

                            Controls.ScrollView {
                                id: previewScroll
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing
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

            function refresh() {
                filledDays = diaryStore.daysWithContent(shownYear, shownMonth)
            }
            function isFilled(day) {
                return filledDays.indexOf("%1-%2-%3".arg(shownYear)
                    .arg(("0" + shownMonth).slice(-2))
                    .arg(("0" + day).slice(-2))) >= 0
            }
            function isPastDay(day) {
                const today = new Date()
                const date = new Date(shownYear, shownMonth - 1, day)
                return shownYear === today.getFullYear()
                    && shownMonth === today.getMonth() + 1
                    && date < new Date(today.getFullYear(), today.getMonth(), today.getDate())
            }
            function isCurrentDay(day) {
                const today = new Date()
                return shownYear === today.getFullYear()
                    && shownMonth === today.getMonth() + 1
                    && day === today.getDate()
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
                            id: dayButton
                            required property int index
                            property int firstWeekday: new Date(calendar.shownYear, calendar.shownMonth - 1, 1).getDay()
                            property int dayNumber: index - firstWeekday + 1
                            visible: dayNumber > 0 && dayNumber <= new Date(calendar.shownYear, calendar.shownMonth, 0).getDate()
                            width: (monthGrid.width - monthGrid.spacing * 6) / 7
                            text: visible ? dayNumber : ""
                            highlighted: visible && calendar.isFilled(dayNumber)
                            background: Rectangle {
                                radius: Kirigami.Units.smallSpacing
                                color: diaryStore.highlightCurrentDay && calendar.isCurrentDay(dayNumber)
                                    ? Kirigami.Theme.highlightColor : "transparent"
                            }
                            contentItem: Controls.Label {
                                text: dayButton.text
                                color: dayButton.highlighted
                                    ? Kirigami.Theme.highlightedTextColor
                                    : Kirigami.Theme.textColor
                                opacity: diaryStore.crossOutPastDays && calendar.isPastDay(dayNumber)
                                    ? 0.65 : 1
                                font.strikeout: diaryStore.crossOutPastDays && calendar.isPastDay(dayNumber)
                            }
                            onClicked: root.showDiary("%1-%2-%3".arg(calendar.shownYear)
                                .arg(("0" + calendar.shownMonth).slice(-2))
                                .arg(("0" + dayNumber).slice(-2)))
                        }
                    }

                }
            }
        }
    }

    Component {
        id: settingsPage

        Kirigami.ScrollablePage {
            title: qsTr("Settings")

            Column {
                width: parent.width
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Heading {
                    text: qsTr("Date format")
                    level: 2
                }

                Controls.Label {
                    text: qsTr("Choose how dates are shown and entered.")
                    opacity: 0.8
                }

                Row {
                    width: parent.width
                    spacing: Kirigami.Units.smallSpacing

                    Controls.Label {
                        width: Kirigami.Units.gridUnit * 6
                        text: qsTr("Format:")
                        verticalAlignment: Text.AlignVCenter
                    }

                    Controls.ComboBox {
                        id: dateOrderCombo
                        width: Kirigami.Units.gridUnit * 18
                        model: ["dd mm yyyy", "mm dd yyyy", "yyyy mm dd"]
                        currentIndex: diaryStore.dateOrder === "dd MM yyyy"
                            ? 0 : diaryStore.dateOrder === "MM dd yyyy" ? 1 : 2
                        onActivated: diaryStore.dateOrder = ["dd MM yyyy", "MM dd yyyy", "yyyy MM dd"][currentIndex]
                    }
                }

                Row {
                    width: parent.width
                    spacing: Kirigami.Units.smallSpacing

                    Controls.Label {
                        width: Kirigami.Units.gridUnit * 6
                        text: qsTr("Separator:")
                        verticalAlignment: Text.AlignVCenter
                    }

                    Controls.ComboBox {
                        id: dateSeparatorCombo
                        width: Kirigami.Units.gridUnit * 18
                        model: ["-", "/"]
                        currentIndex: diaryStore.dateSeparator === "/" ? 1 : 0
                        onActivated: diaryStore.dateSeparator = currentIndex === 1 ? "/" : "-"
                    }
                }

                Controls.Label {
                    text: qsTr("Example: %1").arg(diaryStore.currentDate)
                    opacity: 0.8
                }

                Controls.CheckBox {
                    text: qsTr("Cross out past days in the current month")
                    checked: diaryStore.crossOutPastDays
                    onToggled: diaryStore.crossOutPastDays = checked
                }

                Controls.CheckBox {
                    text: qsTr("Highlight the current day")
                    checked: diaryStore.highlightCurrentDay
                    onToggled: diaryStore.highlightCurrentDay = checked
                }
            }
        }
    }
}
