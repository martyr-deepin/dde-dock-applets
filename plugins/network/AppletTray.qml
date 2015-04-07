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
import QtQuick.Window 2.1
import Deepin.DockAppletWidgets 1.0
import Deepin.Widgets 1.0
import DBus.Com.Deepin.Daemon.Network 1.0
import DBus.Com.Deepin.Daemon.Bluetooth 1.0
import DBus.Com.Deepin.Api.Graphic 1.0
import Deepin.DockAppletWidgets 1.0

DockApplet{
    id:networkApplet
    title: activeConnectionsCount > 0 ? dsTr("Network Connected") : dsTr("Network Not Connected")
    appid: "AppletNetwork"
    icon: getIcon()

    // device state
    readonly property var nmDeviceStateActivated: 100

    property var dconstants: DConstants {}
    property string currentIconName: ""

    Connections{
        target: root
        onIconThemeNameChanged: {
            updateIconTimer.restart()
        }
    }

    Timer{
        id: updateIconTimer
        interval: 500
        onTriggered: {
            // refresh the icon theme
            currentIconName = root.iconThemeName
        }
    }

    //Graphic
    property var dbusGraphic: Graphic {}
    function getIconBgDataUri() {
        if(dbusNetwork.state == 70){
            var path = mainObject.iconNameToPath("network-online", 48)
        }
        else{
            var path = mainObject.iconNameToPath("network-offline", 48)
        }
        return getIconDataUri(path)
    }
    property var subImageList: ListModel{
        function getTypeIndex(type){
            for(var i=0; i<subImageList.count; i++){
                var imageInfo = subImageList.get(i)
                if(imageInfo.type == type){
                    return i
                }
            }
            return -1

        }
    }

    property bool airplaneModeActive: {
        if(dbusNetwork.networkingEnabled || dbusBluetooth.powered){
            return false
        }
        else{
            return true
        }
    }
    function getWinIcon(){
    }

    function getIcon(){
        // do not delete this line, currentIconName change to emit icon update
        print("==> [info] network icon update:", currentIconName)

        if(dockDisplayMode == 0){
            var iconDataUri = getIconBgDataUri()
            for(var i=0; i<subImageList.count; i++){
                var imageInfo = subImageList.get(i)
                iconDataUri = dbusGraphic.CompositeImageUri(
                            iconDataUri,
                            getIconDataUri(imageInfo.imagePath),
                            imageInfo.x,
                            imageInfo.y,
                            "png"
                            )
            }
            return iconDataUri
        }
        else{
            if(activeWiredDevice){
                return "network-wired-symbolic"
            }
            else{
                return "network-offline-symbolic"
            }
        }
    }

    function getIconDataUri(path){
        print("********* to data uri:", path)
        return dbusGraphic.ConvertImageToDataUri(path)
    }

    property var positions: {
        "vpn": [5, 5],
                "bluetooth": [5, 26],
                "3g": [26, 5],
                "wifi": [26, 26]
    }

    function updateState(type, show, imagePath){
        var index = subImageList.getTypeIndex(type)
        if(show){
            if(index == -1){
                subImageList.append({
                                        "type": type,
                                        "imagePath": imagePath,
                                        "x": positions[type][0],
                                        "y": positions[type][1]
                                    })
            }
            else{
                var info = subImageList.get(index)
                if(info.imagePath != imagePath){
                    info.imagePath = imagePath
                }
            }
        }
        else{
            if(index != -1){
                subImageList.remove(index)
            }
        }
    }

    // wired
    property var nmConnections: unmarshalJSON(dbusNetwork.connections)
    property var activeWiredDevice: getActiveWiredDevice()
    property bool hasWiredDevices: {
        if(nmDevices["wired"] && nmDevices["wired"].length > 0){
            return true
        }
        else{
            return false
        }
    }

    // wifi    property var nmDevices: JSON.parse(dbusNetwork.devices)
    property var wirelessDevicesCount: {
        if (wirelessDevices)
            return wirelessDevices.length
        else
            return 0
    }
    property bool hasWirelessDevices: {
        if(wirelessDevicesCount > 0){
            return true
        }
        else{
            return false
        }
    }
    property var activeWirelessDevice: getActiveWirelessDevice()
    property bool wirelessDevicesActivating: {//for load connecting animation,include all device
        if (wirelessDevices){
            for (var i = 0; i < wirelessDevices.length; i ++){
                if (wirelessDevices[i].State != nmDeviceStateActivated && wirelessDevices[i].ActiveAp != "/"){
                    return true
                }
            }

            return false
        }
        else
            return false
    }

    property var wirelessListModel: ListModel {}

    onActiveWirelessDeviceChanged: {
        if(activeWirelessDevice){
            var allAp = JSON.parse(dbusNetwork.GetAccessPoints(activeWirelessDevice.Path))
            for(var i in allAp){
                var apInfo = allAp[i]
                if(apInfo.Path == activeWirelessDevice.ActiveAp){
                    updateWifiState(true, apInfo)
                }
            }
        }
        else{
            if(hasWirelessDevices){
                updateWifiState(true, null)
            }
            else {
                updateWifiState(false, null)
            }
        }
    }
    onWirelessDevicesCountChanged:{
        if (wirelessDevicesCount > wirelessListModel.count)
            wirelessRepeater.addWirelessApplet()
        else if (wirelessDevicesCount < wirelessListModel.count)
            wirelessRepeater.deleteWirelessApplet()
    }
    onWirelessDevicesActivatingChanged: {
        if (wirelessDevicesActivating)
            connectingIconTimer.start()
        else{
            connectingIconTimer.stop()
            if(hasWirelessDevices){
                updateWifiState(true, null)
            }
            else {
                updateWifiState(false, null)
            }
            connectingIconTimer.signalLevel = 1
        }
    }

    Connections{
        target: dbusNetwork
        onAccessPointPropertiesChanged: {
            if(activeWirelessDevice && arg0 == activeWirelessDevice.Path){
                var apInfo = unmarshalJSON(arg1)
                if(apInfo.Path == activeWirelessDevice.ActiveAp){
                    updateWifiState(true, apInfo)
                }
            }
        }
    }

    Timer {
        id: connectingIconTimer
        interval: 100
        repeat: true

        property int signalLevel: 1

        onTriggered: {
            if (signalLevel == 5)
                signalLevel = 1
            else
                signalLevel ++

            updateConnectingWifiState(signalLevel)
        }
    }

    function updateConnectingWifiState(signalLevel){
        var imagePath = getAbsolutePath("emblems-images/wifi-%1.png".arg(signalLevel))
        updateState("wifi", show, imagePath)
    }

    function updateWifiState(show, apInfo){
        var image_id = 0
        if(show){
            if(!apInfo){
                image_id = 1
            }
            else{
                if(apInfo.Strength <= 25){
                    image_id = 2
                }
                else if(apInfo.Strength <= 50){
                    image_id = 3
                }
                else if(apInfo.Strength <= 75){
                    image_id = 4
                }
                else if(apInfo.Strength <= 100){
                    image_id = 5
                }
            }
        }
        var imagePath = getAbsolutePath("emblems-images/wifi-%1.png".arg(image_id))
        updateState("wifi", show, imagePath)
    }

    //mobile
    property var mobileDevices: nmDevices["modem"] == undefined ? [] : nmDevices["modem"]
    property var mobileListmodel: ListModel {}
    onMobileDevicesChanged: {
        var gotActiveDevice = false
        var maxNetworkLevel = 0
        var maxConnectedNetworkLevel = 0
        for (var i = 0; i < mobileDevices.length; i ++){
            var networkLevel = 0
            if (mobileDevices[i].MobileNetworkType == "Unknown")
                networkLevel = 0
            else if (mobileDevices[i].MobileNetworkType == "2G")
                networkLevel = 2
            else if (mobileDevices[i].MobileNetworkType == "3G")
                networkLevel = 3
            else
                networkLevel = 4

            if (mobileDevices[i].State == 100){
                maxConnectedNetworkLevel = networkLevel > maxConnectedNetworkLevel ? networkLevel : maxConnectedNetworkLevel
                gotActiveDevice = true
            }

            maxNetworkLevel = networkLevel > maxNetworkLevel ? networkLevel : maxNetworkLevel
        }

        //update composite icon
        updateMobileState(mobileDevices.length > 0, gotActiveDevice, maxConnectedNetworkLevel > 0 ? maxConnectedNetworkLevel : maxNetworkLevel)

        //uodate dock window icons
        if (mobileDevices.length > mobileListmodel.count)
            mobileRepeater.addMobileApplet()
        else
            mobileRepeater.deleteMobileApplet()

        mobileRepeater.updateMobileApplet()
    }

    function updateMobileState(show,deviceActived, mobileNetworkLevel){
        var imagePath = getAbsolutePath("emblems-images/%1g-%2.png".arg(mobileNetworkLevel).arg(deviceActived ? "on" : "off"))
        updateState("3g", show, imagePath)
    }

    // vpn
    property var vpnConnections: nmConnections["vpn"]
    property var vpnActived:{
        if (activeConnections){
            for (var key in activeConnections){
                if (activeConnections[key]["Vpn"] && activeConnections[key]["State"] == 2)
                    return true
            }
            return false
        }
        else
            return false
    }

    onVpnConnectionsChanged: updateVpnState()
    onVpnActivedChanged: updateVpnState()

    function updateVpnState(){
        var vpnShow = vpnConnections ? vpnConnections.length > 0 : false
        if(vpnActived){
            var imagePath = getAbsolutePath("emblems-images/vpn-on.png")
        }
        else{
            var imagePath = getAbsolutePath("emblems-images/vpn-off.png")
        }
        updateState("vpn", vpnShow, imagePath)
    }

    // bluetooth
    Bluetooth {
        id: dbusBluetooth
        onAdapterAdded:bluetoothAdapters = unmarshalJSON(dbusBluetooth.GetAdapters())
        onAdapterRemoved:bluetoothAdapters = unmarshalJSON(dbusBluetooth.GetAdapters())
        onAdapterPropertiesChanged: bluetoothAdapters = unmarshalJSON(dbusBluetooth.GetAdapters())
    }
    property var bluetoothAdapters: unmarshalJSON(dbusBluetooth.GetAdapters())
    property var blueToothAdaptersCount: {
        if (bluetoothAdapters)
            return bluetoothAdapters.length
        else
            return 0
    }
    property var bluetoothListmodel: ListModel{}
    property var bluetoothState: dbusBluetooth.state
    onBluetoothStateChanged: {
        bluetoothRepeater.updateBluetoothApplet()
        updateBluetoothState()
    }
    onBlueToothAdaptersCountChanged: {
        bluetoothRepeater.updateBluetoothApplet()
        updateBluetoothState()
    }
    onBluetoothAdaptersChanged: {
        bluetoothRepeater.updateBluetoothApplet()
        updateBluetoothState()
    }

    function updateBluetoothState(){
        var show = blueToothAdaptersCount > 0
        var enabled = bluetoothState == stateConnected

        if(enabled){
            var imagePath = getAbsolutePath("emblems-images/bluetooth-on.png")
        }
        else{
            var imagePath = getAbsolutePath("emblems-images/bluetooth-off.png")
        }
        updateState("bluetooth", show, imagePath)
    }

    property int xEdgePadding: 10

    function getActiveWirelessDevice(){
        for(var i in wirelessDevices){
            var info = wirelessDevices[i]
            if(info.ActiveAp != "/" && info.State == 100){
                return info
            }
        }
        return null
    }

    function getActiveWiredDevice(){
        for(var i in wiredDevices){
            var info = wiredDevices[i]
            if(info.State == 100){
                return info
            }
        }
        return null
    }

    function showNetwork(id){
        dbusControlCenter.ShowModule("network")
    }

    function hideNetwork(id){
        setAppletState(false)
    }

    onActivate: {
        showNetwork(0)
    }

    menu: AppletMenu {
        Component.onCompleted: {
            addItem(dsTr("_Run"), showNetwork);
            addItem(dsTr("_Undock"), hideNetwork);
        }
    }

    window: (dockDisplayMode == 0 && !hasWirelessDevices && !vpnButton.visible && blueToothAdaptersCount <=0) ||
            (hasWiredDevices && !hasWirelessDevices && activeConnectionsCount == 0 && dockDisplayMode != 0) ? null : rootWindow

    DockQuickWindow {
        id: rootWindow
        width: buttonRow.width > 130 ? buttonRow.width + 30 : 130
        height: buttonRow.height
        color: "transparent"

        onNativeWindowDestroyed: {
            toggleAppletState("network")
            toggleAppletState("network")
        }
        onQt5ScreenDestroyed: {
            console.log("Recive onQt5ScreenDestroyed")
            mainObject.restartDockApplet()
        }

        Item {
            anchors.centerIn: parent
            width: parent.width - xEdgePadding * 2
            height: buttonRow.height
            visible: dockDisplayMode == 0

            Row {
                id: buttonRow
                spacing: 16
                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                    id: wirelessRepeater

                    function addWirelessApplet(){
                        for (var i = 0; i < wirelessDevices.length; i ++){
                            var tmpPath = wirelessDevices[i].Path
                            if (getIndexFromWirelessListModel(tmpPath) == -1){//not in model,add it
                                wirelessListModel.append({"wirelessPath": wirelessDevices[i].Path})
                            }
                        }
                    }

                    function deleteWirelessApplet(){
                        var oldDeviceArray = new Array()
                        for (var i = 0; i < wirelessListModel.count; i ++){
                            var tmpPath = wirelessListModel.get(i).wirelessPath
                            if (getIndexFromWirelessDevices(tmpPath) == -1){//not exit,storage it for delete
                                oldDeviceArray.push(tmpPath)
                            }
                        }

                        for (var i = 0; i < oldDeviceArray.length; i ++){
                            wirelessListModel.remove(getIndexFromWirelessListModel(oldDeviceArray[i]))
                        }
                    }

                    function getIndexFromWirelessListModel(devicePath){
                        for (var i = 0; i < wirelessListModel.count; i++){
                            if (wirelessListModel.get(i).wirelessPath == devicePath)
                                return i
                        }

                        return -1
                    }

                    function getIndexFromWirelessDevices(devicepath){
                        for (var i = 0; i < wirelessDevices.length; i ++){
                            if (wirelessDevices[i].Path == devicepath){
                                return i
                            }
                        }

                        return -1
                    }

                    model: wirelessListModel
                    delegate: CheckButton{
                        id: wirelessCheckButton

                        property var pDevicePath: wirelessPath
                        property var pDeviceCount: wirelessDevicesCount

                        onImage: "images/wifi_on.png"
                        offImage: "images/wifi_off.png"
                        visible: true
                        active: dbusNetwork.IsDeviceEnabled(pDevicePath)

                        onPDeviceCountChanged: deviceIndex = pDeviceCount > 1 ? index + 1 : ""

                        onClicked: {
                            if (!dbusNetwork.IsDeviceEnabled(pDevicePath)){
                                print ("==> [Info] Enable wireless device...")
                                dbusNetwork.EnableDevice(pDevicePath,true)
                            }
                            else{
                                dbusNetwork.EnableDevice(pDevicePath,false)
                            }
                        }

                        Connections {
                            target: dbusNetwork
                            onDeviceEnabled:{
                                if (arg0 == wirelessPath)
                                    wirelessCheckButton.active = arg1
                            }
                        }
                    }
                }

                Repeater {
                    id: mobileRepeater

                    function updateMobileApplet(){
                        for (var i = 0; i < mobileListmodel.count; i ++){
                            mobileListmodel.set(i, {
                                                    "mobileNetworkType": mobileDevices[i].MobileNetworkType,
                                                    "deviceState":mobileDevices[i].State,
                                                    "devicesCount":mobileDevices.length
                                                })
                        }
                    }

                    function addMobileApplet(){
                        for (var i = 0; i < mobileDevices.length; i ++){
                            var tmpPath = mobileDevices[i].Path
                            if (getIndexFromMobileListModel(tmpPath) == -1){//not in model,add it
                                mobileListmodel.append({
                                                           "devicesCount":mobileDevices.length,
                                                           "devicePath": mobileDevices[i].Path,
                                                           "mobileNetworkType": mobileDevices[i].MobileNetworkType,
                                                           "deviceState":mobileDevices[i].State
                                                       })}
                        }
                    }

                    function deleteMobileApplet(){
                        var oldDeviceArray = new Array()
                        for (var i = 0; i < mobileListmodel.count; i ++){
                            var tmpPath = mobileListmodel.get(i).devicePath
                            if (getIndexFromMobileDevices(tmpPath) == -1){//not exit,storage it for delete
                                oldDeviceArray.push(tmpPath)
                            }
                        }

                        for (var i = 0; i < oldDeviceArray.length; i ++){
                            mobileListmodel.remove(getIndexFromMobileListModel(oldDeviceArray[i]))
                        }
                    }

                    function getIndexFromMobileListModel(devicePath){
                        for (var i = 0; i < mobileListmodel.count; i++){
                            if (mobileListmodel.get(i).devicePath == devicePath)
                                return i
                        }

                        return -1
                    }

                    function getIndexFromMobileDevices(devicepath){
                        for (var i = 0; i < mobileDevices.length; i ++){
                            if (mobileDevices[i].Path == devicepath){
                                return i
                            }
                        }

                        return -1
                    }

                    model: mobileListmodel
                    delegate: CheckButton{
                        id: mobileCheckButton
                        onImage: "images/%1g-on.png".arg(pMobileNetworkType)
                        offImage: "images/%1g-off.png".arg(pMobileNetworkType)
                        visible: true
                        property var pDeviceCount: devicesCount
                        property var pDeviceState: deviceState
                        property var pMobileNetworkType:{
                            if (mobileNetworkType == "Unknown")
                                return 0
                            else if (mobileNetworkType == "2G")
                                return 2
                            else if (mobileNetworkType == "3G")
                                return 3
                            else
                                return 4
                        }

                        onPDeviceStateChanged: mobileCheckButton.active = dbusNetwork.IsDeviceEnabled(devicePath)
                        onPDeviceCountChanged: deviceIndex = pDeviceCount > 1 ? index + 1 : ""

                        onClicked: {
                            if (!dbusNetwork.IsDeviceEnabled(devicePath)){
                                print ("==> [Info] Enable mobile device...")
                                dbusNetwork.EnableDevice(devicePath,true)
                            }
                            else{
                                dbusNetwork.EnableDevice(devicePath,false)
                            }
                        }
                    }
                }

                CheckButton{
                    id: vpnButton
                    visible: vpnConnections ? vpnConnections.length > 0 : false
                    onImage: "images/vpn_on.png"
                    offImage: "images/vpn_off.png"
                    active: dbusNetwork.vpnEnabled

                    onClicked: {
                        dbusNetwork.vpnEnabled = active
                    }

                    Connections{
                        target: dbusNetwork
                        onVpnEnabledChanged:{
                            if(!vpnButton.pressed){
                                vpnButton.active = dbusNetwork.vpnEnabled
                            }
                        }
                    }

                    Timer{
                        running: true
                        interval: 100
                        onTriggered: {
                            // parent.active = parent.vpnActive
                            parent.active = dbusNetwork.vpnEnabled
                        }
                    }
                }

                Repeater {
                    id:bluetoothRepeater

                    function updateBluetoothApplet(){
                        if (blueToothAdaptersCount > bluetoothListmodel.count)
                            bluetoothRepeater.addBluetoothApplet()
                        else if (blueToothAdaptersCount < bluetoothListmodel.count)
                            bluetoothRepeater.deleteBluetoothApplet()

                        //update data too on add or remove adapter
                        for (var i = 0; i < bluetoothAdapters.length; i ++){
                            var tmpPath = bluetoothAdapters[i].Path
                            var tmpIndex = getIndexFromBluetoothListModel(tmpPath)
                            if (tmpIndex != -1){
                                bluetoothListmodel.setProperty(tmpIndex,"adapterPower", bluetoothAdapters[i].Powered)
                            }

                        }
                    }

                    function addBluetoothApplet(){
                        for (var i = 0; i < bluetoothAdapters.length; i ++){
                            var tmpPath = bluetoothAdapters[i].Path
                            if (getIndexFromBluetoothListModel(tmpPath) == -1){//not in model,add it
                                bluetoothListmodel.append({
                                                              "adapterPath": bluetoothAdapters[i].Path,
                                                              "adapterPower":bluetoothAdapters[i].Powered
                                                          })
                            }
                        }
                    }

                    function deleteBluetoothApplet(){
                        var oldDeviceArray = new Array()
                        for (var i = 0; i < bluetoothListmodel.count; i ++){
                            var tmpPath = bluetoothListmodel.get(i).adapterPath
                            if (getIndexFromBluetoothAdapters(tmpPath) == -1){//not exit,storage it for delete
                                oldDeviceArray.push(tmpPath)
                            }
                        }

                        for (var i = 0; i < oldDeviceArray.length; i ++){
                            bluetoothListmodel.remove(getIndexFromBluetoothListModel(oldDeviceArray[i]))
                        }
                    }

                    function getIndexFromBluetoothListModel(devicePath){
                        for (var i = 0; i < bluetoothListmodel.count; i++){
                            if (bluetoothListmodel.get(i).adapterPath == devicePath)
                                return i
                        }

                        return -1
                    }

                    function getIndexFromBluetoothAdapters(devicepath){
                        for (var i = 0; i < bluetoothAdapters.length; i ++){
                            if (bluetoothAdapters[i].Path == devicepath){
                                return i
                            }
                        }

                        return -1
                    }

                    model: bluetoothListmodel
                    delegate: CheckButton {
                        id: bluetoothButton

                        property var pAdapterPath: adapterPath
                        property var pAdapterPowered: adapterPower
                        property var pAdapterCount: blueToothAdaptersCount

                        visible: true
                        onImage: "images/bluetooth_on.png"
                        offImage: "images/bluetooth_off.png"
                        active: pAdapterPowered
                        deviceIndex: pAdapterCount > 1 ? index + 1 : ""
                        onPAdapterPoweredChanged: {
                            active = pAdapterPowered
                        }

                        onClicked: {
                            dbusBluetooth.SetAdapterPowered(pAdapterPath, pAdapterPowered ? 0 : 1)
                        }
                    }
                }
            }
        }
    }

}
