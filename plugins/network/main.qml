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

import QtQuick 2.1
import DBus.Com.Deepin.Daemon.Network 1.0
import Deepin.DockAppletWidgets 1.0

AppletPlugin {
    id: mainNetworkAppletItem

    managed: true
    show: true
    name: dsTr("Network")
    iconPath: "network-wired-symbolic"
    appletPath: qmlPath


    // device state
    readonly property var nmDeviceStateUnknown: 0
    readonly property var nmDeviceStateUnmanaged: 10
    readonly property var nmDeviceStateUnavailable: 20
    readonly property var nmDeviceStateDisconnected: 30
    readonly property var nmDeviceStatePrepare: 40
    readonly property var nmDeviceStateConfig: 50
    readonly property var nmDeviceStateNeedAuth: 60
    readonly property var nmDeviceStateIpConfig: 70
    readonly property var nmDeviceStateIpCheck: 80
    readonly property var nmDeviceStateSecondaries: 90
    readonly property var nmDeviceStateActivated: 100
    readonly property var nmDeviceStateDeactivating: 110
    readonly property var nmDeviceStateFailed: 120

    // active connection state
    readonly property var nmActiveConnectionStateUnknown: 0
    readonly property var nmActiveConnectionStateActivating: 1
    readonly property var nmActiveConnectionStateActivated: 2
    readonly property var nmActiveConnectionStateDeactivating: 3
    readonly property var nmActiveConnectionStateDeactivate: 4

    // connection type
    readonly property var nmConnectionTypeWired: "wired"
    readonly property var nmConnectionTypeWireless: "wireless"
    readonly property var nmConnectionTypeWirelessAdhoc: "wireless-adhoc"
    readonly property var nmConnectionTypeWirelessHotspot: "wireless-hotspot"
    readonly property var nmConnectionTypePppoe: "pppoe"
    readonly property var nmConnectionTypeMobile: "mobile"
    readonly property var nmConnectionTypeMobileGsm: "mobile-gsm"
    readonly property var nmConnectionTypeMobileCdma: "mobile-cdma"
    readonly property var nmConnectionTypeVpn: "vpn"
    readonly property var nmConnectionTypeVpnL2tp: "vpn-l2tp"
    readonly property var nmConnectionTypeVpnPptp: "vpn-pptp"
    readonly property var nmConnectionTypeVpnVpnc: "vpn-vpnc"
    readonly property var nmConnectionTypeVpnOpenvpn: "vpn-openvpn"
    readonly property var nmConnectionTypeVpnOpenconnect: "vpn-openconnect"

    property var dbusNetwork: NetworkManager{}
    property var nmDevices: JSON.parse(dbusNetwork.devices)
    property var wiredDevices: nmDevices["wired"] == undefined ? [] : nmDevices["wired"]
    property var wirelessDevices: nmDevices["wireless"] == undefined ? [] : nmDevices["wireless"]
    property var nmConnections: unmarshalJSON(dbusNetwork.connections)
    property var activeConnections: unmarshalJSON(dbusNetwork.activeConnections)

    property var activeConnectionsCount: {
        if (activeConnections)
            return  Object.keys(activeConnections).length
        else
            return 0
    }

    property bool hasWiredDevices: {
        if(nmDevices["wired"] && nmDevices["wired"].length > 0){
            return true
        }
        else{
            return false
        }
    }
    // wifi
    property bool hasWirelessDevices: {
        if(nmDevices["wireless"] && nmDevices["wireless"].length > 0){
            return true
        }
        else{
            return false
        }
    }

    property int stateUnavailable: 0
    property int stateAvailable: 1
    property int stateConnected: 2

    Connections {
        target: root
        onDockDisplayModeChanged:{
            updateWiredSettingItem(dockDisplayMode == 0)
        }
    }

    // wired 
    property var activeWiredDevice: getActiveWiredDevice()
    function getActiveWiredDevice(){
        for(var i in wiredDevices){
            var info = wiredDevices[i]
            if(info.State == 100){
                return info
            }
        }
        return null
    }

    // wireless
    property var activeWirelessDevice: getActiveWirelessDevice()
    function getActiveWirelessDevice(){
        for(var i in wirelessDevices){
            var info = wirelessDevices[i]
            if(info.ActiveAp != "/" && info.State == 100){
                return info
            }
        }
        return null
    }

    Timer {
        id: delayUpdateTimer
        repeat: false
        running: true
        interval: 1000
        onTriggered: {
            updateWiredSettingItem(dockDisplayMode == 0)
        }
    }

    function updateWiredSettingItem(showFlag){
        var tmpIndex = appletInfos.indexOf("network")
        if (tmpIndex != -1)
            appletInfos.updateSettingEnable(tmpIndex,showFlag)
    }

    appletTrayLoader: Loader {
        sourceComponent: AppletTray{}
        active: mainNetworkAppletItem.show && ((hasWiredDevices && !hasWirelessDevices) || (activeWiredDevice && !activeWirelessDevice))
    }

    onSubAppletStateChanged: {
        subAppletManager.updateAppletState(subAppletId, subAppletState)
    }

    SubAppletManager {
        id:subAppletManager
        parentAppletPath: mainNetworkAppletItem.appletPath
    }
}
