import QtQuick 2.0
import Nemo.DBus 2.0

Item {
    id: root
    property bool running: false    // Jupii app is running
    property bool connected: false  // Jupii app is connected to UPnP device

    readonly property string _serviceName: "org.mkiol.jupii"

    onRunningChanged: console.log("Jupii running:", running)
    onConnectedChanged: console.log("Jupii connected:", connected)

    onVisibleChanged: ping()

    function ping() {
        if (running) {
            connected = (jupiiPlayer.getProperty('canControl') === true)
        } else {
            connected = false
        }
    }

    function addUrlOnceAndPlay(url, title, author, type, app, icon) {
        if (running) {
            jupiiPlayer.call('add', [url, "", title, author, "", type, app, icon, true, true])
            jupiiPlayer.call('focus')
        }
    }

    function _updateSatatus() {
        dbus.call("NameHasOwner", _serviceName, function(result) {
            root.running = result
            root.ping()
        },
        function(error, message) {
            console.log("updateSatatus error:", error, message)
            root.running = false
            root.ping()
        })
    }

    DBusInterface {
        id: jupiiPlayer

        service: root.running ? _serviceName : ""
        iface: "org.jupii.Player"
        path: "/"
        signalsEnabled: root.running

        function canControlPropertyChanged(canControl) {
            connected = canControl
        }
    }

    DBusInterface {
        id: dbus

        service: "org.freedesktop.DBus"
        iface: "org.freedesktop.DBus"
        path: "/org/freedesktop/DBus"
        signalsEnabled: true

        function nameOwnerChanged(name, oldOwner, newOwner) {
            if (name === _serviceName) {
                root._updateSatatus()
            }
        }
    }
}
