#include "plugin.h"
#include "dock_quick_window.h"

#include <qqml.h>

void DockAppletPlugin::registerTypes(const char *uri)
{
    //@uri Deepin.DockAppletWidgets
    qmlRegisterType<DockQuickWindow>(uri, 1, 0, "DockQuickWindow");
    qmlRegisterType<DockApplet>(uri, 1, 0, "DockApplet");
    qmlRegisterType<DockMenu>(uri, 1, 0, "DockMenu");
}


