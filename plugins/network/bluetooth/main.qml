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
import DBus.Com.Deepin.Daemon.Bluetooth 1.0

AppletPlugin {
    id: appletItem

    managed: true
    show: true
    name: appletName == "" ? appletId : appletName
    iconPath: "bluetooth-active-symbolic"

    Bluetooth {
        id: dbusBluetooth
        onAdapterPropertiesChanged: {
            var tmpAdapter = unmarshalJSON(arg0)
            var tmpIndex = appletInfos.indexOf(tmpAdapter.Path)
            if (tmpIndex != -1)
                appletInfos.updateAppletName(tmpIndex,tmpAdapter.Alias)
            if (tmpAdapter.Path == appletId){
                adapterAlias = tmpAdapter.Alias
                adapterPowered = tmpAdapter.Powered

            }
        }
    }
    property bool adapterPowered: false
    property string adapterAlias: ""
    property string adapterPath: ""
    property bool loaderActive: blueToothAdaptersCount > 0 && appletItem.show && dockMode != 0//not mac mode

    property var dockMode: dockDisplayMode

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

    Component.onCompleted:{
        var tmpAdapters = unmarshalJSON(dbusBluetooth.GetAdapters())
        for (var i = 0; i < tmpAdapters.length; i ++){
            if (tmpAdapters[i].Path == appletId){
                adapterPath = tmpAdapters[i].Path
                adapterAlias = tmpAdapters[i].Alias
                adapterPowered = tmpAdapters[i].Powered
                break
            }
        }
    }
}
