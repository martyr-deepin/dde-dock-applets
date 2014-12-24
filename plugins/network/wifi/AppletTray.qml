/****************************************************************************
**
**  Copyright (C) 2011~2014 Deepin, Inc.
**                2011~2014 Wanqing Yang
**
**  Author:     Wanqing Yang <yangwanqing@linuxdeepin.com>
**  Maintainer: Wanqing Yang <yangwanqing@linuxdeepin.com>
**
**  This program is free software: you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation, either version 3 of the License, or
**  any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License
**  along with this program.  If not, see <http://www.gnu.org/licenses/>.
**
****************************************************************************/


import QtQuick 2.0
import QtQuick.Window 2.1
import Deepin.Widgets 1.0
import Deepin.DockAppletWidgets 1.0
import DBus.Com.Deepin.Daemon.Network 1.0

DockApplet{
    id: wifiApplet
    title: "Wireless Network"
    appid: vendor

    icon: ""

    Component.onCompleted: {
        updateDockIcon()
    }

    property int xEdgePadding: 2
    property int titleSpacing: 10
    property int rootWidth: 200
    property int deviceIndex: {
        for (var i = 0; i < wirelessDevices.length; i++){
            if (wirelessDevices[i].Vendor == appletId){
                return i
            }
        }
        return 0
    }

    property var wirelessDevice: wirelessDevices[deviceIndex]
    property string activeAp: typeof(wirelessDevice) != "undefined" ? wirelessDevices[deviceIndex].ActiveAp : "/"
    property string devicePath: typeof(wirelessDevice) != "undefined" ? wirelessDevices[deviceIndex].Path : "/"
    property var wirelessEnabled : typeof(wirelessDevice) != "undefined" ? dbusNetwork.IsDeviceEnabled(devicePath) : false
    property int deviceStatus: wirelessDevices[deviceIndex].State
    property string vendor: wirelessDevices[deviceIndex].Vendor
    property string deviceHwAddress: wirelessDevices[deviceIndex].HwAddress

    property var nmActiveConnections: unmarshalJSON(dbusNetwork.activeConnections)
    property var nmConnections: unmarshalJSON(dbusNetwork.connections)

    Connections {
        target: dbusNetwork
        onDeviceEnabled:{
            wirelessEnabled = dbusNetwork.IsDeviceEnabled(devicePath)
        }
    }

    ListModel {
        id: accessPointsModel

        function getIndexByApPath(path){
            for(var i=0; i<count; i++){
                var obj = get(i)
                if(obj.apPath == path){
                    return i
                }
            }
            return -1
        }

        function getInsertPosition(apObj){
            for(var i=0; i<count; i++){
                var obj = get(i)
                if(apObj.Path != obj.apPath && apObj.Strength >= obj.apSignal){
                    return i
                }
            }
            return count
        }
    }

    function updateDockIcon() {
        if(!wirelessEnabled) {
            wifiApplet.icon = "network-wireless-signal-none-symbolic"
            return
        }

        if (dbusNetwork.state >= 50 && dbusNetwork.state <= 60) {
            wifiApplet.icon = "network-wireless-offline-symbolic"
        }
        else {
            if(accessPointsModel.count == 0){
                if (contentLoader.item)
                    contentLoader.item.initMode()
            }

            if(activeAp == "/") {
                wifiApplet.icon = "network-wirelss-no-route-symbolic"
            }
            else{
                for (var i = 0; i < accessPointsModel.count; i ++) {
                    if (accessPointsModel.get(i).apPath == activeAp) {
                        var apPower = accessPointsModel.get(i).apSignal

                        if (apPower < 5)
                            wifiApplet.icon = "network-wireless-signal-none-symbolic"
                        else if (apPower <= 25)
                            wifiApplet.icon = "network-wireless-signal-weak-symbolic"
                        else if (apPower <= 50)
                            wifiApplet.icon = "network-wireless-signal-ok-symbolic"
                        else if (apPower <= 75)
                            wifiApplet.icon = "network-wireless-signal-good-symbolic"
                        else
                            wifiApplet.icon = "network-wireless-signal-excellent-symbolic"
                        break
                    }
                }
            }

            if (wifiApplet.icon == ""){
                wifiApplet.icon = "network-wireless-signal-none-symbolic"
            }
        }

    }

    function unmarshalJSON(valueJSON) {
        if (!valueJSON) {
            print("==> [ERROR] unmarshalJSON", valueJSON)
        }
        var value = JSON.parse(valueJSON)
        return value
    }

    function showNetwork(id){
        dbusControlCenter.ShowModule("network")
    }

    function hideNetwork(id){
        setAppletState(false)
    }

    menu: AppletMenu{
        Component.onCompleted: {
            addItem(dsTr("_Run"), showNetwork);
            addItem(dsTr("_Undock"), hideNetwork);
        }
    }

    onActivate:{
        showNetwork(0)
    }



    window: DockQuickWindow {
        id: rootWindow
        width: rootWidth
        height: contentLoader.height + xEdgePadding * 2
        color: "transparent"

        onNativeWindowDestroyed: {
            toggleAppletState(appid)
            toggleAppletState(appid)
        }

        onQt5ScreenDestroyed: {
            console.log("Recive onQt5ScreenDestroyed")
            mainObject.restartDockApplet()
        }

        function showContent(show){
            contentLoader.active = show
        }

        Loader {//the content must destroy befor DockQuickWindow
            id:contentLoader
            width: parent.width
            height: item ? item.height : 0
            active: loaderActive

            sourceComponent: Item {
                height: content.height
                anchors.centerIn: parent

                function initMode(){
                    contantRec.initMode()
                }

                Column {
                    id: content
                    width: parent.width

                    DBaseLine {
                        height: 30
                        width: parent.width
                        leftMargin: 10
                        rightMargin: 10
                        //                    color: "#000000"
                        color:"transparent"
                        leftLoader.sourceComponent: DssH2 {
                            elide:Text.ElideRight
                            width:130
                            text: wirelessDevices.length > 1 ? vendor : dsTr("Wireless Network")
                            color: "#ffffff"
                        }

                        rightLoader.sourceComponent: DSwitchButton {
                            id:wirelessSwitchButton
                            checked: wirelessEnabled
                            Connections{
                                target: wifiApplet
                                onWirelessEnabledChanged:{
                                    wirelessSwitchButton.checked = wirelessEnabled
                                }
                            }
                            onClicked: dbusNetwork.EnableDevice(devicePath,checked)
                        }
                    }

                    Rectangle {
                        id: contantRec
                        width: rootWidth
                        height: apListView.height
                        visible: wirelessEnabled
                        color: "transparent"

                        Connections {
                            target: dbusNetwork
                            onAccessPointAdded:{
                                if(arg0 == devicePath){
                                    var apObj = unmarshalJSON(arg1)
                                    var index = accessPointsModel.getIndexByApPath(apObj.Path)
                                    if(index == -1){
                                        var insertPosition = accessPointsModel.getInsertPosition(apObj)
                                        accessPointsModel.insert(insertPosition, {
                                                                     "apName": apObj.Ssid,
                                                                     "apSecured": apObj.Secured,
                                                                     "apSecuredInEap": apObj.SecuredInEap,
                                                                     "apSignal": apObj.Strength,
                                                                     "apPath": apObj.Path
                                                                 })
                                    }

                                    updateDockIcon()
                                }
                            }

                            onAccessPointRemoved: {
                                if(arg0 == devicePath){
                                    var apObj = unmarshalJSON(arg1)
                                    var index = accessPointsModel.getIndexByApPath(apObj.Path)
                                    if(index != -1){
                                        accessPointsModel.remove(index, 1)
                                    }

                                    updateDockIcon()
                                }
                            }

                            onAccessPointPropertiesChanged: {
                                if(arg0 == devicePath){
                                    var apObj = unmarshalJSON(arg1)
                                    var index = accessPointsModel.getIndexByApPath(apObj.Path)
                                    if (index != -1){
                                        var apModelObj = accessPointsModel.get(index)
                                        apModelObj.apName = apObj.Ssid
                                        apModelObj.apSecured = apObj.Secured
                                        apModelObj.apSecuredInEap = apObj.SecuredInEap
                                        apModelObj.apSignal = apObj.Strength
                                        apModelObj.apPath = apObj.Path
                                    }

                                    updateDockIcon()
                                }
                            }

                            onDeviceEnabled: {
                                if (arg0 == devicePath){
                                    updateDockIcon()
                                }
                            }
                        }

                        DConstants {
                            id:dContants
                        }

                        ListView {
                            id:apListView
                            width: parent.width
                            height: Math.min(childrenRect.height, 235)
                            model: accessPointsModel
                            delegate: WirelessApItem {}
                            visible: accessPointsModel.count > 0
                            clip: true

                            DScrollBar {
                                flickable: parent
                            }
                        }


                        function initMode(){
                            var accessPoints = unmarshalJSON(dbusNetwork.GetAccessPoints(devicePath))
                            accessPointsModel.clear()

                            for(var i in accessPoints){
                                // TODO ap
                                var apObj = accessPoints[i]
                                accessPointsModel.append({
                                                             "apName": apObj.Ssid,
                                                             "apSecured": apObj.Secured,
                                                             "apSecuredInEap": apObj.SecuredInEap,
                                                             "apSignal": apObj.Strength,
                                                             "apPath": apObj.Path
                                                         })
                            }
                            contantRec.sortModel()
                            sortModelTimer.start()
                        }

                        Timer {
                            id: sortModelTimer
                            interval: 1000
                            repeat: true
                            onTriggered: {
                                contantRec.sortModel()
                            }
                        }

                        function sortModel()
                        {
                            var n;
                            var i;
                            for(n=0; n < accessPointsModel.count; n++){
                                for(i=n+1; i < accessPointsModel.count; i++){
                                    if (accessPointsModel.get(n).apSignal < accessPointsModel.get(i).apSignal){
                                        accessPointsModel.move(i, n, 1);
                                        n=0; // Repeat at start since I can't swap items i and n
                                    }
                                }
                            }
                        }
                    }
                }
            }

        }
    }

}
