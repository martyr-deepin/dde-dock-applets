TEMPLATE = lib
TARGET = dock-applet-widgets
QT += qml quick dbus
CONFIG += qt plugin

TARGET = $$qtLibraryTarget($$TARGET)
uri = Deepin.DockAppletWidgets

HEADERS += \
    dock_quick_window.h \
    plugin.h

SOURCES += \
    dock_quick_window.cpp \
    plugin.cpp

installPath = $$[QT_INSTALL_QML]/$$replace(uri, \\., /)

qmldir.files += *.qml qmldir
qmldir.path = $$installPath

target.path = $$installPath

INSTALLS += target qmldir
