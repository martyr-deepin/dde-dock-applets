import QtQuick 2.1
import QtQuick.Window 2.0
import Deepin.Widgets 1.0
import DBus.Com.Deepin.Api.XMouseArea 1.0
import DBus.Com.Deepin.Daemon.Display 1.0
import DBus.Com.Deepin.Daemon.Dock 1.0

DWindow {
    id: root
    flags: Qt.Dialog | Qt.FramelessWindowHint | Qt.Popup | Qt.WindowStaysOnTopHint
    width: titleLine.width
    height: switchListView.height + titleLine.height
    x: 0
    y: screenSize.height - height - dockHeight - 10
    color: "transparent"

    signal itemClicked(string switchId, bool switchState)

    property int mouseX:0
    property var dockRegion: DockRegion {}
    property int dockDisplayMode: dbusDockSetting.GetDisplayMode()
    property int dockHeight:70

    property int mX:0
    property int mY:0
    property var screenSize: QtObject {
        property int x: displayId.primaryRect[0]
        property int y: displayId.primaryRect[1]
        property int width: displayId.primaryRect[2]
        property int height: displayId.primaryRect[3]
    }

    function updateRootY(){
        var regionValue = dockRegion.GetDockRegion()
        if (regionValue){
            dockHeight = regionValue[3]
        }
        else
            dockHeight = 70

        root.y = screenSize.y +  screenSize.height - appletInfos.getVisibleSwitchCount() * 30 - titleLine.height - dockHeight - 10
    }

    function getLegalX(mouseX){
        if (mouseX < screenSize.x + width/2)
            x = screenSize.x + width/2
        else if (mouseX > screenSize.x + screenSize.width - width/2)
            x = screenSize.x + screenSize.width - width/2
        else
            x = mouseX
        return x - width/2
    }

    function showWindow(){
        root.x = getLegalX(root.mouseX)
        updateRootY()
        root.show()
    }

    function isInsideWindow(mousex,mousey){
        var width = root.width
        var height = root.height
        var x = root.x
        var y = root.y

        if (mousex > x + screenSize.x && mousex < x + screenSize.x + width
                && mousey > y + screenSize.y && mousey < y +screenSize.y + height)
            return true
        else
            return false
    }

    XMouseArea {
        id:xmouseArea
        onCursorMove:{
            mX = arg0
            mY = arg1
        }
        onButtonPress: {
            if (!isInsideWindow(arg1,arg2))
                root.hide()
        }
    }
    Display {
        id:displayId
    }

    Rectangle {
        anchors.fill: parent
        radius: 2
        color: "#000000"
        opacity: 0.8

    }

    Column {
        anchors.fill: parent
        width: titleLine.width - 4
        height: switchListView.height + titleLine.height
        spacing: 0

        Rectangle {
            id:titleLine
            height: 30
            width: contentWidth < 180 ? 180 : contentWidth
            color: "transparent"

            property int contentWidth: titleText.width + closeButton.width + 50

            Text {
                id:titleText
                text: dsTr("Notification Area Settings")
                color: "#ffffff"
                font.pixelSize: 14
                anchors.centerIn: parent
                verticalAlignment: Text.AlignVCenter
            }

            DDragableArea {
                anchors.fill: parent
                window: root
            }

            DImageButton{
                id: closeButton
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.hide()

                normal_image: "images/close_normal.png"
                hover_image: "images/close_hover.png"
                press_image: "images/close_press.png"
            }

            DSeparatorHorizontal{
                width: parent.width - 20
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                opacity: 0.7
            }
        }

        ListView {
            id:switchListView
            clip: true
            height: childrenRect.height
            width: parent.width
            model: appletInfos
            boundsBehavior: Flickable.StopAtBounds
            delegate: AppletSwitchLine{
                height: setting_enable ? 30 : 0
                onClicked: root.itemClicked(switchId,switchState)
            }
        }

    }
}
