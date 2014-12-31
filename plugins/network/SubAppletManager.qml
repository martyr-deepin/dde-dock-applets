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
    property int oldBluetoothAdapterCount: 0

    property var wirelessListModel: ListModel {}
    property var bluetoothListModel: ListModel {}

    property var dockMode:dockDisplayMode
    property int oldWirelessDeviceCount:0

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

    function getIndexFromAppletInfos(id){
        for (var i = 0; i < appletInfos.count; i ++){
            if (appletInfos.get(i).applet_id == id)
                return i
        }
        return -1
    }

    function isInWirelessList(id){
        for (var i = 0; i < wirelessDevicesCount; i ++){
            if (wirelessDevices[i].Vendor == id)
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
            var vendor = wirelessDevices[i].Vendor
            if (getIndexFromWirelessMode(vendor) == -1){//not in mode, add it
                wirelessListModel.append({
                                             "applet_id": vendor,
                                             "applet_path": getParentAppletPathHead() + "wifi/main.qml"
                                         })
            }
            if (wirelessDevicesCount > 1){
                var infoIndex = getIndexFromAppletInfos(vendor)
                if (infoIndex != -1)
                    appletInfos.get(infoIndex).applet_name = vendor
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
            appletInfos.remove(getIndexFromAppletInfos(oldIdArray[i]))
            wirelessListModel.remove(getIndexFromWirelessMode(oldIdArray[i]))
        }

        if (wirelessListModel.count == 1){
            appletInfos.get(0).applet_name = dsTr("Wireless Network")
        }
    }

    function addVpnApplet() {
        if (!vpnLoader.item)
            return

        for (var i = 0; i < appletInfos.count; i ++){
            if (appletInfos.get(i).applet_id == "vpn"){
                return
            }
        }

        //not exist ,insert new one
        appletInfos.append({
            "applet_id": "vpn",
            "applet_name": vpnLoader.item.name,
            "applet_visible": vpnLoader.item.show,
            "applet_icon": vpnLoader.item.iconPath,
            "setting_enable":true
        })
    }

    function deleteVpnApplet(){
        for (var i = 0; i < appletInfos.count; i ++){
            if (appletInfos.get(i).applet_id == "vpn"){
                appletInfos.remove(i)
            }
        }
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
            appletInfos.remove(getIndexFromAppletInfos(oldIdArray[i]))
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
            //try bluetooth device applet
            for (i = 0; i < bluetoothRepeater.count; i ++){
                if (bluetoothListModel.get(i).applet_id == applet_id){
                    bluetoothRepeater.itemAt(i).item.setAppletState(new_state)
                }
            }
        }
    }

    function updateSettingItem(showFlag){
        for (var i = 0; i < appletInfos.count; i ++){
            if (appletInfos.get(i).applet_id == "vpn" ||
                    isInWirelessList(appletInfos.get(i).applet_id) ||
                    isInBluetoothList(appletInfos.get(i).applet_id)){
                appletInfos.get(i).setting_enable = showFlag
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
