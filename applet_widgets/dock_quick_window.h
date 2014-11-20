#ifndef MYITEM_H
#define MYITEM_H

#include <QQuickItem>
#include <QQuickWindow>
#include <QDBusAbstractAdaptor>
#include <QPointer>

class DockAppletDBus;
class DockApplet;
class DockMenu;

class DockMenu: public QQuickItem
{
    Q_OBJECT
    Q_DISABLE_COPY(DockMenu)

    Q_PROPERTY(QString content READ content WRITE setContent NOTIFY contentChanged)
public:
    DockMenu(QQuickItem* parent = 0);
    ~DockMenu();

    const QString& content() { return m_content; }
    void setContent(const QString& m) {
        m_content = m;
        Q_EMIT contentChanged(m_content);
    }
    Q_SIGNAL void contentChanged(QString);

    Q_SIGNAL void activate(QString id);
private:
    QString m_content;
};

class DockQuickWindow: public QQuickWindow
{
    Q_OBJECT
    Q_DISABLE_COPY(DockQuickWindow)

public:
    DockQuickWindow(QQuickWindow *parent = 0);
    ~DockQuickWindow();

    // when x window destroy. emit this
    Q_SIGNAL void nativeWindowDestroyed();
    //This signal just for Qt5 double screen switch bug
    //When screen switch,
    Q_SIGNAL void qt5ScreenDestroyed();


private:
    Q_SLOT void handleScreenChanged(QScreen* s);
    bool nativeEvent(const QByteArray &eventType, void *message, long *result);
};

class DockApplet : public QQuickItem {
    Q_OBJECT
    Q_DISABLE_COPY(DockApplet)

    Q_PROPERTY(DockMenu* menu READ menu WRITE setMenu)
    Q_PROPERTY(QString appid READ id WRITE setId NOTIFY idChanged)
    Q_PROPERTY(QString icon READ icon WRITE setIcon NOTIFY iconChanged)
    Q_PROPERTY(QString title READ title WRITE setTitle NOTIFY titleChanged)
    Q_PROPERTY(qint32 status READ status WRITE setStatus NOTIFY statusChanged)
    Q_PROPERTY(DockQuickWindow* window READ window WRITE setWindow NOTIFY windowChanged)
public:
    DockApplet(QQuickItem *parent = 0);
    ~DockApplet();

    void setWindow(DockQuickWindow*);
    DockQuickWindow* window() { return m_window; }
    Q_SIGNAL void windowChanged(DockQuickWindow*);

    const QString& id() { return m_id; }
    void setId(const QString& v) { m_id = v; Q_EMIT idChanged(v);}
    Q_SIGNAL void idChanged(QString);

    DockMenu* menu() {return m_menu; }
    void setMenu(DockMenu* v);
    Q_SLOT void setMenuContent(const QString& c);
    void handleMenuItem(QString id);

    const QString& icon() {return m_icon; }
    void setIcon(const QString& v);
    Q_SIGNAL void iconChanged(QString);

    const QString& title() {return m_title; }
    void setTitle(const QString& v);
    Q_SIGNAL void titleChanged(QString);

    qint32 status() {return m_status; }
    void setStatus(const qint32 v);
    Q_SIGNAL void statusChanged(qint32);

    Q_SIGNAL void activate(qint32 x, qint32 y);
    Q_SIGNAL void secondaryActivate(qint32 x, qint32 y);
    Q_SIGNAL void dragdrop(qint32 x, qint32 y, const QString&);
    Q_SIGNAL void dragenter(qint32 x, qint32 y, const QString&);
    Q_SIGNAL void dragleave(qint32 x, qint32 y, const QString&);
    Q_SIGNAL void dragover(qint32 x, qint32 y, const QString&);
    Q_SIGNAL void mousewheel(qint32 x, qint32 y, qint32 angleDelta);


    Q_INVOKABLE void setData(QString key, QString value);

private:
    QString m_id;
    QString m_icon;
    QString m_title;
    qint32 m_status;
    DockAppletDBus* m_dbus_proxyer;
    QPointer<DockMenu> m_menu;
    QPointer<DockQuickWindow> m_window;
};

typedef QMap<QString,QString> StringMap;
Q_DECLARE_METATYPE(StringMap)

class DockAppletDBus : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "dde.dock.Entry")

    Q_PROPERTY(QString Id READ id)
    Q_PROPERTY(QString Type READ type)
    Q_PROPERTY(StringMap Data READ data)

public:
    DockAppletDBus(DockApplet* parent);
    ~DockAppletDBus();

    const StringMap& data() {
        return m_data;
    }
    const QString type() { return "Applet"; }
    const QString id() { return m_parent->id(); }

    void setData(const QString& k, const QString& v) {
        m_data[k] = v;
        Q_EMIT DataChanged(k,v);
    }
    void clearData(const QString& k) {
        m_data.remove(k);
        Q_EMIT DataChanged(k, "");
    }

    Q_SLOT void ShowQuickWindow();
    Q_SLOT void Activate(qint32 x, qint32 y);
    Q_SLOT void SecondaryActivate(qint32 x, qint32 y);
    Q_SLOT void ContextMenu(qint32 x, qint32 y);
    Q_SLOT void HandleMenuItem(QString id);
    Q_SLOT void HandleDragDrop(qint32 x, qint32 y, const QString& data);
    Q_SLOT void HandleDragEnter(qint32 x, qint32 y, const QString& data);
    Q_SLOT void HandleDragLeave(qint32 x, qint32 y, const QString& data);
    Q_SLOT void HandleDragOver(qint32 x, qint32 y, const QString& data);
    Q_SLOT void HandleMouseWheel(qint32 x, qint32 y, qint32 angleDelta);

    Q_SIGNAL void DataChanged(QString, QString);

private:
    QString m_id;
    StringMap  m_data;
    DockApplet* m_parent;
};

#endif // MYITEM_H
