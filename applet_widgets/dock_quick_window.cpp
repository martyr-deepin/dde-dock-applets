#include "dock_quick_window.h"
#include <QDBusConnection>
#include <QDBusMetaType>
#include <QUuid>
#include <xcb/xcb.h>

DockQuickWindow::DockQuickWindow(QQuickWindow *parent):
    QQuickWindow(parent)
{
    QSurfaceFormat sformat;
    sformat.setAlphaBufferSize(8);
    this->setFormat(sformat);
    this->setClearBeforeRendering(true);

    connect(this, SIGNAL(screenChanged(QScreen*)), this, SLOT(handleScreenChanged(QScreen*)));
}

DockQuickWindow::~DockQuickWindow()
{
}

void DockQuickWindow::handleScreenChanged(QScreen* s)
{
    if (s == 0) {
        Q_EMIT qt5ScreenDestroyed();
    }
}

bool DockQuickWindow::nativeEvent(const QByteArray &eventType, void *message, long *result)
{
    Q_UNUSED(result);
    if (eventType != "xcb_generic_event_t") {
        return false;
    }

    xcb_generic_event_t *event = static_cast<xcb_generic_event_t*>(message);
    const uint8_t responseType = event->response_type & ~0x80;
    if (responseType == XCB_DESTROY_NOTIFY) {
        Q_EMIT nativeWindowDestroyed();
    }
    return false;
}


void DockApplet::setMenu(DockMenu* m)
{
    if (m_menu) {
        disconnect(m_menu, SIGNAL(contentChanged(QString)), this, SLOT(setMenuContent(QString)));
    }
    m_menu = m;

    if (m_menu) {
        connect(m_menu, SIGNAL(contentChanged(QString)), this, SLOT(setMenuContent(QString)));
        setMenuContent(m_menu->content());
    } else {
        setMenuContent("");
    }
}

void DockApplet::setMenuContent(const QString &c)
{
    setData("menu", c);
}

void DockApplet::handleMenuItem(QString id)
{
    if (m_menu) {
        Q_EMIT m_menu->activate(id);
    }
}


void DockApplet::setIcon(const QString& v)
{
    m_icon = v;
    setData("icon", v);
    Q_EMIT iconChanged(v);
}

void DockApplet::setTitle(const QString& v)
{
    m_title= v;
    setData("title", v);
    Q_EMIT titleChanged(v);
}

void DockApplet::setStatus(const qint32 v)
{
    m_status = v;
    setData("status", QString::number(v));
    Q_EMIT statusChanged(v);
}

void DockApplet::setData(QString key, QString value)
{
    if (value == "") {
        m_dbus_proxyer->clearData(key);
    } else {
        m_dbus_proxyer->setData(key, value);
    }
}

void DockApplet::setWindow(DockQuickWindow* w)
{
    m_window = w;

    if (m_window) {
        setData("app-xids", QString("[{\"Xid\":%1,\"Title\":\"\"}]").arg(w->winId()));
    } else {
        setData("app-xids", "");
    }
    Q_EMIT windowChanged(w);
}

DockApplet::DockApplet(QQuickItem *parent)
    :QQuickItem(parent),
    m_dbus_proxyer(new DockAppletDBus(this))
{
}

DockApplet::~DockApplet()
{
}


DockAppletDBus::DockAppletDBus(DockApplet* parent) :
    QDBusAbstractAdaptor(parent),
    m_parent(parent)
{
    qDBusRegisterMetaType<StringMap>();
    m_id = QUuid::createUuid().toString().replace("{", "").replace("}", "").replace("-", "");
    QDBusConnection::sessionBus().registerService("dde.dock.entry.Applet" + m_id);
    qDebug() << "Register:" << QDBusConnection::sessionBus().registerObject("/dde/dock/entry/v1/Applet" + m_id, parent);
}
DockAppletDBus::~DockAppletDBus()
{
    QDBusConnection::sessionBus().unregisterService("dde.dock.entry.Applet" + m_id);
    qDebug() << "Unregister:" << "dde.dock.entry.Applet" + m_id;
}

void DockAppletDBus::HandleMenuItem(QString id)
{
    m_parent->handleMenuItem(id);
}

void DockAppletDBus::HandleDragDrop(qint32 x, qint32 y, const QString &data)
{
    Q_EMIT m_parent->dragdrop(x, y, data);
}

void DockAppletDBus::HandleDragEnter(qint32 x, qint32 y, const QString &data)
{
    Q_EMIT m_parent->dragenter(x, y, data);
}

void DockAppletDBus::HandleDragLeave(qint32 x, qint32 y, const QString &data)
{
    Q_EMIT m_parent->dragleave(x, y, data);
}

void DockAppletDBus::HandleDragOver(qint32 x, qint32 y, const QString &data)
{
    Q_EMIT m_parent->dragover(x, y, data);
}

void DockAppletDBus::HandleMouseWheel(qint32 x, qint32 y, qint32 angleDelta)
{
    Q_EMIT m_parent->mousewheel(x, y, angleDelta);
}

void DockAppletDBus::ShowQuickWindow()
{
    DockQuickWindow * window = m_parent->window();
    if (window) {
        QScreen * pScreen = window->screen();
        // TODO: Bugfix, remove when qt fix this bug
        if (NULL == pScreen) {
            return;
        }
        window->show();
    }
}

void DockAppletDBus::Activate(qint32 x, qint32 y)
{
    Q_EMIT m_parent->activate(x, y);
}

void DockAppletDBus::SecondaryActivate(qint32 x, qint32 y)
{
    Q_EMIT m_parent->secondaryActivate(x, y);
}

void DockAppletDBus::ContextMenu(qint32 x, qint32 y)
{
    qDebug() << "Hasn't support" << x << y;
}

DockMenu::DockMenu(QQuickItem *parent)
    :QQuickItem(parent)
{

}

DockMenu::~DockMenu()
{
}
