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
import DBus.Com.Deepin.Daemon.Bluetooth 1.0

Item {
    id:managerItem

    property string parentAppletPath:""

    readonly property string nmConnectionTypeVpn: "vpn"
    property var dbusNetwork: NetworkManager{}
    property var nmConnections: unmarshalJSON(dbusNetwork.connections)
    property var activeConnections: unmarshalJSON(dbusNetwork.activeConnections)
    property var nmDevices: JSON.parse(dbusNetwork.devices)

    property var wiredDevices:nmDevices["wired"] == undefined ? [] : nmDevices["wired"]

    property var vpnConnections: nmConnections[nmConnectionTypeVpn]
    property var vpnConnectionsCount: {
        if (vpnConnections)
            return vpnConnections.length
        else
            return 0
    }

    property var wirelessDevices: nmDevices["wireless"] == undefined ? [] : nmDevices["wireless"]
    property var wirelessDevicesCount:{
        if (wirelessDevices)
            return wirelessDevices.length
        else
            return 0
    }

    property var mobileDevices: nmDevices["modem"] == undefined ? [] : nmDevices["modem"]
    property int mobileDeviceCount: {
        if (mobileDevices)
            return mobileDevices.length
        else
            return 0
    }

    Bluetooth {
        id: dbusBluetooth
        onAdapterAdded:bluetoothAdapters = unmarshalJSON(dbusBluetooth.GetAdapters())
        onAdapterRemoved:bluetoothAdapters = unmarshalJSON(dbusBluetooth.GetAdapters())
        onAdapterPropertiesChanged:bluetoothAdapters = unmarshalJSON(dbusBluetooth.GetAdapters())
    }
    property var bluetoothAdapters: unmarshalJSON(dbusBluetooth.GetAdapters())
    property var blueToothAdaptersCount: {
        if (bluetoothAdapters)
            return bluetoothAdapters.length
        else
            return 0
    }

    property var wirelessListModel: ListModel {}
    property var mobileListModel: ListModel {}
    property var bluetoothListModel: ListModel {}

    property int oldWirelessDeviceCount:0
    property int oldMobileDeviceCount: 0
    property int oldBluetoothAdapterCount: 0

    property var dockMode:dockDisplayMode

    onDockModeChanged: {
        print ("==> [Info] Dock display mode change...",dockMode)
        updateSettingItem(dockMode != 0)
    }

    Component.onCompleted: updateSettingItem(dockMode != 0)

    onWirelessDevicesCountChanged: {
        //update wireless model
        if (oldWirelessDeviceCount < wirelessDevicesCount){
            addWirelessApplet()
        }
        else{
            deleteWirelessApplet()
        }
        oldWirelessDeviceCount = wirelessDevicesCount

        updateSettingItem(dockDisplayMode != 0)
    }

    onMobileDeviceCountChanged: {
        //update mobile model
        if (oldMobileDeviceCount < mobileDeviceCount){
            addMobileApplet()
        }
        else{
            deleteMobileApplet()
        }
        oldMobileDeviceCount = mobileDeviceCount

        updateSettingItem(dockDisplayMode != 0)
    }

    onBlueToothAdaptersCountChanged: {
        //update bluetooth model
        if (oldBluetoothAdapterCount < blueToothAdaptersCount){
            addBluetoothApplet()
        }
        else{
            deleteBluetoothApplet()
        }
        oldBluetoothAdapterCount = blueToothAdaptersCount

        updateSettingItem(dockDisplayMode != 0)
    }

    onVpnConnectionsCountChanged: {
        if (vpnConnectionsCount == 0)
            deleteVpnApplet()
        else
            addVpnApplet()
    }

    function getParentAppletPathHead(){
        if (parentAppletPath != "")
            return parentAppletPath.substring(0,parentAppletPath.length - 8)//"main.qml" got 8 character
        else
            return ""
    }

    function isInWirelessList(id){
        for (var i = 0; i < wirelessDevicesCount; i ++){
            if (wirelessDevices[i].Path == id)
                return true
        }
        return false
    }

    function getIndexFromWirelessMode(id){
        for (var i = 0; i < wirelessListModel.count; i ++){
            if (wirelessListModel.get(i).applet_id == id)
                return i
        }
        return -1
    }

    function isInMobileList(id){
        for (var i = 0; i < mobileDeviceCount; i ++){
            if (mobileDevices[i].Path == id)
                return true
        }
        return false
    }

    function getIndexFromMobileModel(id){
        for (var i = 0; i < mobileListModel.count; i ++){
            if (mobileListModel.get(i).applet_id == id)
                return i
        }
        return -1
    }

    function getIndexFromBluetoothMode(id){
        for (var i = 0; i < bluetoothListModel.count; i ++){
            if (bluetoothListModel.get(i).applet_id == id)
                return i
        }
        return -1
    }

    function isInBluetoothList(id){
        for (var i = 0; i < blueToothAdaptersCount; i ++){
            if (bluetoothAdapters[i].Path == id)
                return true
        }
        return false
    }

    function addWirelessApplet(){
        if (getParentAppletPathHead() == "")
            return
        print("==> [Info] Adding Wifi applet...")

        for (var i = 0; i < wirelessDevicesCount; i ++){
            var devicePath = wirelessDevices[i].Path
            if (getIndexFromWirelessMode(devicePath) == -1){//not in mode, add it
                wirelessListModel.append({
                                             "applet_id": devicePath,
                                             "applet_name":wirelessDevices[i].Vendor,
                                             "applet_path": getParentAppletPathHead() + "wifi/main.qml"
                                         })
            }
            if (wirelessDevicesCount > 1){
                var infoIndex = appletInfos.indexOf(devicePath)
                if (infoIndex != -1)
                    appletInfos.updateAppletName(infoIndex,wirelessDevices[i].Vendor)
            }

        }
    }

    function deleteWirelessApplet(){
        var oldIdArray = new Array()
        for (var i = 0; i < wirelessListModel.count; i ++){//get invalid one,prepare to delete
            if (!isInWirelessList(wirelessListModel.get(i).applet_id)){
                oldIdArray.push(wirelessListModel.get(i).applet_id)
            }
        }

        for (i = 0; i < oldIdArray.length; i ++){//delete invalid from mode
            appletInfos.rmItem(oldIdArray[i])
            wirelessListModel.remove(getIndexFromWirelessMode(oldIdArray[i]))
        }

        if (wirelessListModel.count == 1){
            var tmpAppletId = wirelessListModel.get(0).applet_id
            for (var i = 0; i < appletInfos.count; i ++){
                if (appletInfos.get(i).applet_id == tmpAppletId){
                    appletInfos.get(i).applet_name = dsTr("Wireless Network")
                    return
                }
            }
        }
    }

    function addMobileApplet(){
        if (getParentAppletPathHead() == "")
            return
        print("==> [Info] Adding Mobile applet...")

        for (var i = 0; i < mobileDeviceCount; i ++){
            var devicePath = mobileDevices[i].Path
            if (getIndexFromMobileModel(devicePath) == -1){//not in mode, add it
                mobileListModel.append({
                                             "applet_id": devicePath,
                                             "applet_name":mobileDevices[i].Vendor,
                                             "applet_path": getParentAppletPathHead() + "mobile/main.qml"
                                         })
            }
        }
    }

    function deleteMobileApplet(){
        var oldIdArray = new Array()
        for (var i = 0; i < mobileListModel.count; i ++){//get invalid one,prepare to delete
            if (!isInMobileList(mobileListModel.get(i).applet_id)){
                oldIdArray.push(mobileListModel.get(i).applet_id)
            }
        }

        for (i = 0; i < oldIdArray.length; i ++){//delete invalid from mode
            appletInfos.remove(getIndexFromAppletInfos(oldIdArray[i]))
            mobileListModel.remove(getIndexFromMobileModel(oldIdArray[i]))
        }
    }

    function addVpnApplet() {
        if (!vpnLoader.item || appletInfos.indexOf("vpn") != -1)
            return

        //not exist ,insert new one
        appletInfos.update("vpn", vpnLoader.item.name, vpnLoader.item.show,vpnLoader.item.iconPath)
    }

    function deleteVpnApplet(){
        appletInfos.rmItem("vpn")
    }

    function addBluetoothApplet(){
        if (getParentAppletPathHead() == "")
            return
        print("==> [Info] Adding bluetooth applet...")

        for (var i = 0; i < blueToothAdaptersCount; i ++){
            var adapterPath = bluetoothAdapters[i].Path
            if (getIndexFromBluetoothMode(adapterPath) == -1){//not in mode, add it
                bluetoothListModel.append({
                                             "applet_id": adapterPath,
                                             "applet_name":bluetoothAdapters[i].Alias,
                                             "applet_path": getParentAppletPathHead() + "bluetooth/main.qml"
                                         })
            }
        }
    }

    function deleteBluetoothApplet(){
        var oldIdArray = new Array()
        for (var i = 0; i < bluetoothListModel.count; i ++){//get invalid one,prepare to delete
            if (!isInBluetoothList(bluetoothListModel.get(i).applet_id)){
                oldIdArray.push(bluetoothListModel.get(i).applet_id)
            }
        }

        for (i = 0; i < oldIdArray.length; i ++){//delete invalid from mode
            appletInfos.rmItem(oldIdArray[i])
            bluetoothListModel.remove(getIndexFromBluetoothMode(oldIdArray[i]))
        }
    }

    function updateAppletState(applet_id, new_state){
        print ("==> Update applet state...",applet_id,new_state)
        if (applet_id == "vpn")
            vpnLoader.item.setAppletState(new_state)
        else{
            //try wireless devices applet
            for (var i = 0; i < wirelessRepeater.count; i ++){
                print("wireless...:",wirelessRepeater.itemAt(i).item.appletId)
                if(wirelessListModel.get(i).applet_id == applet_id){
                    wirelessRepeater.itemAt(i).item.setAppletState(new_state)
                    return
                }
            }
            //try mobile devices applet
            for (var i = 0; i < mobileRepeater.count; i ++){
                print("mobile...:",mobileRepeater.itemAt(i).item.appletId)
                if(mobileListModel.get(i).applet_id == applet_id){
                    mobileRepeater.itemAt(i).item.setAppletState(new_state)
                    return
                }
            }
            //try bluetooth device applet
            for (var i = 0; i < bluetoothRepeater.count; i ++){
                if (bluetoothListModel.get(i).applet_id == applet_id){
                    bluetoothRepeater.itemAt(i).item.setAppletState(new_state)
                }
            }
        }
    }

    //some applet should not show in mac mode
    function updateSettingItem(showFlag){
        for (var i = 0; i < appletInfos.count; i ++){
            var tmpId = appletInfos.get(i).applet_id
            if (tmpId == "vpn" ||
                    isInWirelessList(tmpId) ||
                    isInBluetoothList(tmpId) ||
                    isInMobileList(tmpId)){

                appletInfos.updateSettingEnable(i,showFlag)
            }
        }
    }

    AppletLoader {
        id:vpnLoader
        appletId:"vpn"
        qmlPath:getParentAppletPathHead() + "vpn/main.qml"
        onShowChanged: {
            appletInfos.update(appletId, itemName, itemShow, itemIconPath)
        }
    }

    Repeater {
        id: wirelessRepeater
        model: wirelessListModel
        delegate: AppletLoader {
            onShowChanged: {
                appletInfos.update(appletId, itemName, itemShow, itemIconPath)
            }
        }
    }

    Repeater {
        id: mobileRepeater
        model: mobileListModel
        delegate: AppletLoader {
            onShowChanged: {
                appletInfos.update(appletId, itemName, itemShow, itemIconPath)
            }
        }
    }

    Repeater {
        id:bluetoothRepeater
        model:bluetoothListModel
        delegate: AppletLoader {
            onShowChanged: {
                //bluetooth's itemName may change
                appletInfos.update(appletId, bluetoothAdapters[index].Alias, itemShow, itemIconPath)
            }
        }
    }

}
