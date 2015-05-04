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

import QtQuick 2.1
import Deepin.DockAppletWidgets 1.0
import DBus.Com.Deepin.Daemon.Network 1.0

AppletPlugin {
    id: appletItem

    managed: true
    show: true
    name: wirelessDevices.length > 1 ? appletName : dsTr("Wireless Network")
    iconPath: "network-wireless-signal-excellent-symbolic"

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

    property bool loaderActive: appletItem.show && dockDisplayMode != 0 && !(activeWiredDevice && !activeWirelessDevice)

    Timer {
        id:loaderDelayTimer
        interval: 300
        repeat: false
        running: false
        onTriggered: appletTrayLoader.active = loaderActive
    }

    onLoaderActiveChanged:{
        loaderDelayTimer.start()
    }

    appletTrayLoader: Loader {
        sourceComponent: AppletTray{}
        active: false
    }
}
