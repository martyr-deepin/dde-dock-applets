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
    name: appletName    //show in setting window's item name
    iconPath: "network-mobile-unknown-online-symbolic"

    property bool loaderActive: appletItem.show && dockDisplayMode != 0
    property var dbusNetwork: NetworkManager{}
    property var nmDevices: JSON.parse(dbusNetwork.devices)
    property var mobileDevices: nmDevices["modem"] == undefined ? [] : nmDevices["modem"]
    property var deviceCount: {
        if (mobileDevices)
            return mobileDevices.length
        else
            return 0
    }
    property int deviceIndex: {
        for (var i = 0; i < mobileDevices.length; i++){
            if (mobileDevices[i].Path == appletId){
                return i
            }
        }
        return 0
    }
    onMobileDevicesChanged: updateAppletIcon()
    onDeviceIndexChanged: updateAppletIcon()
    Component.onCompleted:updateAppletIcon()

    function updateAppletIcon(){
        var tmpPath = ""
        if (mobileDevices[deviceIndex].MobileNetworkType == "Unknown")
            tmpPath = "network-mobile-unknown-online-symbolic"
        else if (mobileDevices[deviceIndex].MobileNetworkType == "2G")
            tmpPath = "network-mobile-2g-online-symbolic"
        else if (mobileDevices[deviceIndex].MobileNetworkType == "3G")
            tmpPath = "network-mobile-3g-online-symbolic"
        else
            tmpPath = "network-mobile-4g-online-symbolic"

        appletItem.iconPath = tmpPath
    }

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
