TEMPLATE = app
TARGET = dde-dock-applets

QT += quick qml core dbus widgets

SOURCES += \
    main.cpp \
    qmlloader.cpp

HEADERS += \
    qmlloader.h

RESOURCES += \
    frame.qrc \

#VARIABLES
isEmpty(PREFIX) {
    PREFIX = /usr
}
BINDIR = $$PREFIX/bin
DATADIR = $$PREFIX/share
DOCKAPPLETSDIR = $$DATADIR/dde-dock-applets

DEFINES += DATADIR=\\\"$$DATADIR\\\" DOCKAPPLETSDIR=\\\"$$DOCKAPPLETSDIR\\\"

#MAKE INSTALL

target.path =$$BINDIR

plugins.files = ../plugins/*
plugins.path = $$DOCKAPPLETSDIR/plugins

INSTALLS += target plugins

CONFIG += link_pkgconfig
PKGCONFIG += gtk+-2.0
