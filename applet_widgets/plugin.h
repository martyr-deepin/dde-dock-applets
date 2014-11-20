#ifndef DOCK_APPLET_PLUGIN_H
#define DOCK_APPLET_PLUGIN_H

#include <QQmlExtensionPlugin>

class DockAppletPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "Deepin.DockAppletWidgets")

public:
    void registerTypes(const char *uri);
};

#endif // UNTITLED_PLUGIN_H

