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
    id: mobileApplet
    title: "Mobile Network"
    appid: devicePath

    icon: ""

    Component.onCompleted: {
        updateDockIcon()
    }

    // device state
    readonly property var nmDeviceStateDisconnected: 30
    readonly property var nmDeviceStateActivated: 100

    property int xEdgePadding: 2
    property int titleSpacing: 10
    property int rootWidth: 200

    property var mobileDevice: mobileDevices[deviceIndex]
    property string devicePath: typeof(mobileDevice) != "undefined" ? mobileDevices[deviceIndex].Path : "/"
    property var mobileEnabled : typeof(mobileDevice) != "undefined" ? dbusNetwork.IsDeviceEnabled(devicePath) : false
    property string mobileNetworkType: typeof(mobileDevice) != "undefined" ? mobileDevices[deviceIndex].MobileNetworkType : "Unknown"
    property int deviceStatus: typeof(mobileDevice) != "undefined" ? mobileDevices[deviceIndex].State : 0
    property string vendor: typeof(mobileDevice) != "undefined" ? mobileDevices[deviceIndex].Vendor : ""
    property var uniqueUuid:  typeof(mobileDevice) != "undefined" ? mobileDevices[deviceIndex].UniqueUuid : ""
    property string totalSented: "1024 kbps"//TODO
    property string totalReceived: "1024 kbps"//TODO

    onDeviceStatusChanged: {
        print ("[info] ==> mobile device status change:",deviceStatus)
        if (deviceStatus != nmDeviceStateActivated && deviceStatus != nmDeviceStateDisconnected){
            connectingIconTimer.restart()
        }
        else{
            connectingIconTimer.stop()
            updateDockIcon()
        }
    }

    onMobileNetworkTypeChanged: {
        updateDockIcon()
    }

    Connections {
        target: dbusNetwork
        onDeviceEnabled:{
            if (devicePath == arg0) {
                mobileEnabled = arg1

                //Try to active connection after device turned on
                if (mobileEnabled){
                    dbusNetwork.ActivateConnection(uniqueUuid, devicePath)
                }
            }
        }
    }

    Timer {
        id:connectingIconTimer
        interval: 200
        repeat: true

        property string showState: "offline"

        onTriggered: {
            showConnectionAnimation(showState)
            showState = showState == "offline" ? "online" : "offline"
        }
    }

    function showConnectionAnimation(state){
        if (mobileNetworkType == "Unknown"){
            mobileApplet.icon = "network-mobile-unknown-%1-symbolic".arg(state)
        }
        else if (mobileNetworkType == "2G"){
            mobileApplet.icon = "network-mobile-2g-%1-symbolic".arg(state)
        }
        else if (mobileNetworkType == "3G"){
            mobileApplet.icon = "network-mobile-3g-%1-symbolic".arg(state)
        }
        else{
            mobileApplet.icon = "network-mobile-4g-%1-symbolic".arg(state)
        }
    }

    function updateDockIcon() {
        var connectStatus = "offline"
        if (deviceStatus == nmDeviceStateActivated) {
            connectStatus = "online"
        }

        if (mobileNetworkType == "Unknown"){
            mobileApplet.icon = "network-mobile-unknown-%1-symbolic".arg(connectStatus)
        }
        else if (mobileNetworkType == "2G"){
            mobileApplet.icon = "network-mobile-2g-%1-symbolic".arg(connectStatus)
        }
        else if (mobileNetworkType == "3G"){
            mobileApplet.icon = "network-mobile-3g-%1-symbolic".arg(connectStatus)
        }
        else{
            mobileApplet.icon = "network-mobile-4g-%1-symbolic".arg(connectStatus)
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

                Column {
                    id: content
                    width: parent.width

                    DBaseLine {
                        height: 30
                        width: parent.width
                        leftMargin: 10
                        rightMargin: 10
                        color:"transparent"
                        leftLoader.sourceComponent: DssH2 {
                            elide:Text.ElideRight
                            width:130
                            text: vendor
                            color: "#ffffff"
                        }

                        rightLoader.sourceComponent: DSwitchButton {
                            id:mobileSwitchButton
                            checked: mobileEnabled
                            Connections{
                                target: mobileApplet
                                onMobileEnabledChanged:{
                                    mobileSwitchButton.checked = mobileEnabled
                                }
                            }
                            onClicked: dbusNetwork.EnableDevice(devicePath,checked)
                        }
                    }

                    Rectangle {
                        width: rootWidth
                        height: 0//visible ? 60 : 0
                        visible: mobileApplet.mobileEnabled
                        color: "transparent"

//                        Column {
//                            width: parent.width
//                            height: parent.height

//                            DBaseLine {
//                                height: 30
//                                width: parent.width
//                                leftMargin: 10
//                                rightMargin: 15
//                                color:"transparent"
//                                leftLoader.sourceComponent: DssH2 {
//                                    elide:Text.ElideRight
//                                    width:130
//                                    text: dsTr("Sented")
//                                    color: "#ffffff"
//                                }

//                                rightLoader.sourceComponent: DssH2 {
//                                    horizontalAlignment: Text.AlignRight
//                                    width:70
//                                    text: totalSented
//                                    color: "#ffffff"
//                                }
//                            }

//                            DBaseLine {
//                                height: 30
//                                width: parent.width
//                                leftMargin: 10
//                                rightMargin: 15
//                                color:"transparent"
//                                leftLoader.sourceComponent: DssH2 {
//                                    elide:Text.ElideRight
//                                    width:130
//                                    text: dsTr("Received")
//                                    color: "#ffffff"
//                                }

//                                rightLoader.sourceComponent: DssH2 {
//                                    horizontalAlignment: Text.AlignRight
//                                    width:70
//                                    text: totalReceived
//                                    color: "#ffffff"
//                                }
//                            }
//                        }
                    }
                }
            }
        }
    }

}
