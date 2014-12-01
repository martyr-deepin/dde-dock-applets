/****************************************************************************
**
**  Copyright (C) 2011~2014 Deepin, Inc.
**                2011~2014 Kaisheng Ye
**
**  Author:     Kaisheng Ye <kaisheng.ye@gmail.com>
**  Maintainer: Kaisheng Ye <kaisheng.ye@gmail.com>
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
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import Deepin.Widgets 1.0
import Deepin.DockAppletWidgets 1.0
import DBus.Com.Deepin.Daemon.Network 1.0

Item {
    id: wirelessItem
    width: parent.width
    height: 30

    property string connectionPath
    property string uuid
    property bool apConnected: apPath == activeAp && deviceStatus == 100

    property bool hovered: false
    property bool selected: false

    MouseArea{
        anchors.fill:parent
        hoverEnabled: true
        onEntered: parent.hovered = true
        onExited: parent.hovered = false
        onClicked: {
            if(!apConnected){
                print("activate connection")
                activateThisConnection()
            }
        }
    }

    Item {
        height: parent.height
        width: parent.width

        AppletConnectButton {
            id:checkImg
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            visible: apConnected
            onClicked: {
                dbusNetwork.DisconnectDevice(devicePath)
            }
        }

        AppletWaitingImage {
            anchors.left: checkImg.left
            anchors.verticalCenter: parent.verticalCenter
            on: apPath == activeAp && deviceStatus != 100
        }

        DLabel {
            id: nameLabel
            anchors.left: checkImg.right
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
            text: apName
            elide: Text.ElideRight
            width: parent.width - anchors.leftMargin - checkImg.width - signalImage.width - signalImage.anchors.rightMargin
            font.pixelSize: 12
            color: {
                if(selected){
                    return dconstants.activeColor
                }
                else if(hovered){
                    return dconstants.hoverColor
                }
                else{
                    return dconstants.fgColor
                }
            }
        }
    }

    Image {
        id: signalImage
        anchors.right: parent.right
        anchors.rightMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        source: {
            var power = apSignal
            var secure = apSecured ? "-secure": ""
            if (power <= 5)
                return getIconUrl("wifi/ap-signal-0" + secure + ".png")
            else if (power <= 25)
                return getIconUrl("wifi/ap-signal-25" + secure + ".png")
            else if (power <= 50)
                return getIconUrl("wifi/ap-signal-50" + secure + ".png")
            else if (power <= 75)
                return getIconUrl("wifi/ap-signal-75" + secure + ".png")
            else if (power <= 100)
                return getIconUrl("wifi/ap-signal-100" + secure + ".png")
        }
    }

    Behavior on height {
        PropertyAnimation { duration: 100 }
    }

    Connections {
        target: dbusNetwork
        onConnectionsChanged: {
            updateWirelessConnectionInfo()
        }
    }

    Component.onCompleted: {
        updateWirelessConnectionInfo()
    }

    function updateWirelessConnectionInfo() {
        if(nmConnections){
            var wirelessConnections = nmConnections["wireless"]
            var connectionPath = ""
            var uuid = ""
            for (var i in wirelessConnections) {
                if (apName == wirelessConnections[i].Ssid) {
                    if (wirelessConnections[i].HwAddress == "" || wirelessConnections[i].HwAddress == deviceHwAddress) {
                        connectionPath = wirelessConnections[i].Path
                        uuid = wirelessConnections[i].Uuid
                        break
                    }
                }
            }
            wirelessItem.connectionPath = connectionPath
            wirelessItem.uuid = uuid
        }
    }

    function activateThisConnection(){
        if (apSecuredInEap && uuid == "") {
            print("secured in eap") // TODO debug
        } else {
            print("activateAPConnection:", apPath, devicePath)
            dbusNetwork.ActivateAccessPoint(wirelessItem.uuid,apPath, devicePath)
        }
    }

}
