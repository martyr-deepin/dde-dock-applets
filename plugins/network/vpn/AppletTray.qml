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
import Deepin.DockAppletWidgets 1.0
import Deepin.DockAppletWidgets 1.0
import Deepin.Widgets 1.0
import DBus.Com.Deepin.Daemon.Network 1.0

DockApplet{
    id: vpnApplet
    title: "VPN"
    appid: "AppletVPN"
    icon: isVpnConnected ? "network-vpn-active-symbolic" : "network-vpn-disable-symbolic"

    property int xEdgePadding: 2
    property int titleSpacing: 10
    property int rootWidth: 200

    property var vpnEnable:dbusNetwork.vpnEnabled
    property var vpnConnections: nmConnections[nmConnectionTypeVpn]
    property int vpnConnectionNumber: vpnConnections ? vpnConnections.length : 0

    property var isVpnConnected: {
        if (nmActiveConnections){
            for (var key in nmActiveConnections){
                if (nmActiveConnections[key]["Vpn"] && nmActiveConnections[key]["State"] == 2)
                    return true
            }
            return false
        }
        else
            return false
    }

    function showNetwork(id){
        dbusControlCenter.ShowModule("network")
    }

    function hideVPN(id){
        setAppletState(false)
    }

    menu: AppletMenu{
        Component.onCompleted: {
            addItem(dsTr("_Run"), showNetwork);
            addItem(dsTr("_Undock"), hideVPN);
        }
    }

    onActivate:{
        showNetwork(0)
    }

    window: DockQuickWindow {
        id: root
        width: rootWidth
        height: contentLoader.height + xEdgePadding * 2
        color: "transparent"

        onNativeWindowDestroyed: {
            toggleAppletState("vpn")
            toggleAppletState("vpn")
        }

        onQt5ScreenDestroyed: {
            console.log("Recive onQt5ScreenDestroyed")
            mainObject.restartDockApplet()
        }

        Loader {
            id:contentLoader
            width: parent.width
            height: item ? item.height : 0
            active: loaderActive
            sourceComponent: Rectangle {
                height: content.height
                anchors.centerIn: parent
                color: "transparent"

                Column {
                    id: content
                    width: parent.width

                    DBaseLine {
                        height: 30
                        width: parent.width
                        leftMargin: 10
                        rightMargin: 10
                        color: "transparent"
                        leftLoader.sourceComponent: DssH2 {
                            text: dsTr("VPN")
                            color: "#ffffff"
                        }

                        rightLoader.sourceComponent: DSwitchButton {
                            Connections {
                                // TODO still need connections block here, but why?
                                target: vpnApplet
                                onVpnEnableChanged: {
                                    checked = vpnApplet.vpnEnable
                                }
                            }
                            checked: vpnApplet.vpnEnable
                            onClicked: dbusNetwork.vpnEnabled = checked
                        }
                    }


                    Rectangle {
                        id: contantRec

                        property bool itemVisible: false

                        width: rootWidth
                        height: vpnApplet.vpnEnable ? vpnConnectlist.height : 0
                        Behavior on height {
                            NumberAnimation {
                                duration: 100;
                                easing.type: Easing.OutBack
                            }
                        }
                        onHeightChanged: {
                            if (height == vpnConnectlist.height)
                                contantRec.itemVisible = true
                            else
                                contantRec.itemVisible = false
                        }
                        color: "transparent"

                        ListView {
                            id: vpnConnectlist
                            width: parent.width
                            height: Math.min(vpnConnectionNumber * 30, 225)
                            boundsBehavior: Flickable.StopAtBounds
                            model: vpnConnectionNumber
                            delegate: ConnectItem {
                                visible: contantRec.itemVisible
                            }
                            clip: true
                        }
                    }
                }
            }
        }
    }

}
