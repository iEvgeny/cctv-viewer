#ifndef EVENTFILTER_H
#define EVENTFILTER_H

#include <QtCore>
#include <QGuiApplication>
#include <QQmlParserStatus>

class EventFilter : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)

    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(Scope scope READ scope WRITE setScope NOTIFY scopeChanged)
    Q_PROPERTY(QVariant eventTypes READ eventTypes WRITE setEventTypes NOTIFY eventTypesChanged)
    Q_PROPERTY(bool eventProperties READ eventProperties WRITE setEventProperties NOTIFY eventPropertiesChanged)

public:
    enum class Scope {
        Application,
        Parent
    };
    Q_ENUM(Scope)

    EventFilter(QObject *parent = nullptr);

    void classBegin() override { }
    void componentComplete() override { installEventFilter(); }
    bool eventFilter(QObject *watched, QEvent *event) override;

    bool enabled() const { return m_enabled; }
    Scope scope() const { return m_scope; }
    QVariant eventTypes() const;
    bool eventProperties() const { return m_eventProperties; }

public slots:
    void setEnabled(bool enabled);
    void setScope(Scope scope);
    void setEventTypes(const QVariant &events);
    void setEventProperties(bool enabled);

signals:
    void enabledChanged();
    void scopeChanged();
    void eventTypesChanged();
    void eventPropertiesChanged();
    void eventFiltered(const QVariantMap &properties);

protected:
    void installEventFilter();

private:
    bool m_enabled;
    Scope m_scope;
    QObject *m_watched;
    std::vector<QEvent::Type> m_eventTypes;
    bool m_eventProperties;
    QMetaEnum m_metaEnum;
};

#endif // EVENTFILTER_H
