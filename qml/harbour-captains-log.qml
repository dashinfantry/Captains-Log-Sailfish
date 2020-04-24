import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import Nemo.Notifications 1.0
import io.thp.pyotherside 1.5
import "pages"

ApplicationWindow
{
    id: appWindow
    allowedOrientations: defaultAllowedOrientations

    initialPage: useCodeProtection.value === 1 ? pinPage : firstPage
    cover: Qt.resolvedUrl("cover/CoverPage.qml")

    property ListModel entriesModel: ListModel { }

    // constants
    readonly property string timezone: new Date().toLocaleString(Qt.locale("C"), "t")
    readonly property string timeFormat: qsTr("hh':'mm")
    readonly property string atTimeFormat: qsTr("'at' hh':'mm")
    readonly property string dateTimeFormat: qsTr("d MMM yyyy, hh':'mm")
    readonly property string fullDateTimeFormat: qsTr("ddd d MMM yyyy, hh':'mm")
    readonly property string fullDateFormat: qsTr("ddd d MMM yyyy")
    readonly property string dateFormat: qsTr("d MMM yyyy")
    readonly property string dbDateFormat: "dd.MM.yyyy | hh:mm:ss"
    property var moodTexts: [
        qsTr("fantastic"),
        qsTr("good"),
        qsTr("okay"),
        qsTr("not okay"),
        qsTr("bad"),
        qsTr("horrible")
    ]
    readonly property string appVersionNumber: "1.0"
    // ---------

    // global helper functions
    function parseDate(dbDateString) {
        if (typeof dbDateString === 'undefined' || dbDateString === "") return "";
        var dateTime = dbDateString.split(' | ');
        var date = dateTime[0].split('.');
        var time = dateTime[1].split(':');
        var sec = time.length >= 3 ? parseInt(time[2]) : 0

        // Date object interpreted as local time
        return new Date(parseInt(date[2]), parseInt(date[1])-1, parseInt(date[0]), parseInt(time[0]), parseInt(time[1]), sec);
    }

    function formatDate(dbDateString, format, zone) {
        var date = parseDate(dbDateString).toLocaleString(Qt.locale(), format)
        if (zone !== undefined && zone !== "" && zone !== timezone) {
            return qsTr("%1 (%2)", "1: date, 2: time zone info").arg(date).arg(zone)
        }

        return date
    }

    function setFavorite(model, index, rowid, setTrue) {
        py.call("diary.update_favorite", [rowid, setTrue])
        model.setProperty(index, 'favorite', setTrue)
        entryFavoriteToggled(rowid, setTrue)
        if (model !== entriesModel) _scheduleReload = true;
    }

    function updateEntry(model, index, changeDate, mood, title, preview, entry, hashs, rowid) {
        model.set(index, { "modify_date": changeDate, "mood": mood, "title": title,
                             "preview": preview, "entry": entry, "hashtags": hashs, "rowid": rowid })
        py.call("diary.update_entry", [changeDate, mood, title, preview, entry, hashs, rowid], function() {
            console.log("Updated entry in database")
            entryUpdated(changeDate, mood, title, preview, entry, hashs, rowid)
            if (model !== entriesModel) _scheduleReload = true;
        })
    }

    function addEntry(creationDate, mood, title, preview, entry, hashs) {
        py.call("diary.add_entry", [creationDate, mood, title, preview, entry, hashs], function(entry) {
            console.log("Added entry to database")
            entriesModel.insert(0, entry);
        })
    }

    function deleteEntry(model, index, rowid) {
        py.call("diary.delete_entry", [rowid])
        model.remove(index)
        if (model !== entriesModel) _scheduleReload = true;
    }

    function loadModel() {
        _modelReady = false;
        _scheduleReload = false;
        loadingStarted()
        console.log("loading entries...")

        py.call("diary.read_all_entries", [], function(result) {
                entriesModel.clear()
                for(var i=0; i<result.length; i++) {
                    var item = result[i];
                    entriesModel.append(item)
                }

                loadingFinished()
                _modelReady = true;
            }
        )
    }

    signal loadingStarted()
    signal loadingFinished()
    signal entryUpdated(var changeDate, var mood, var title, var preview, var entry, var hashs, var rowid)
    signal entryFavoriteToggled(var rowid, var isFavorite)
    // -----------------------

    property bool _modelReady: false
    property bool _scheduleReload: false // schedules the model to be reloaded when FirstPage ist activated

    property int _lastNotificationId: 0
    property bool unlocked: useCodeProtection.value === 1 ? false : true

    onUnlockedChanged: {
        if (!unlocked) {
            entriesModel.clear()
            _modelReady = false
        } else if (py.ready && !_modelReady) {
            loadModel()
        }
    }

    ConfigurationValue {
        id: useCodeProtection
        key: "/useCodeProtection"
    }

    Component {
        id: pinPage
        PinPage {
            expectedCode: protectionCode.value
            onAccepted: pageStack.push(Qt.resolvedUrl("pages/FirstPage.qml"))
            ConfigurationValue {
                id: protectionCode
                key: "/protectionCode"
            }
        }
    }

    Component  {
        id: firstPage
        FirstPage {}
    }

    Notification {
        id: notification
        expireTimeout: 4000
    }

    function showMessage(msg)
    {
        notification.replacesId = _lastNotificationId
        notification.previewBody = msg
        notification.publish()
        _lastNotificationId = notification.replacesId
    }

    Python {
        id: py
        property bool ready: false

        Component.onCompleted: {
            // Add the directory of this .qml file to the search path
            addImportPath(Qt.resolvedUrl('.'))
            importModule("diary", function() {console.log("diary.py loaded")})
            ready = true

            // Load the model for the first time.
            // If the app is locked and unlocked, the model will be reloaded
            // in onUnlockedChanged.
            loadModel()
        }
    }
}

