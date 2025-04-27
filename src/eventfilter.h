#ifndef EVENTFILTER_H
#define EVENTFILTER_H

#include <QQmlParserStatus>
#include <QMetaEnum>
#include <QEvent>

#include "utils.h"

class EventFilter : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)

    Q_PROPERTY(QVariant eventTypes READ eventTypes WRITE setEventTypes NOTIFY eventTypesChanged)

public:
    enum class Scope {
        Application,
        Parent
    };
    Q_ENUM(Scope)

    EventFilter(QObject *parent = nullptr);

    PROPERTY_MUTABLE(bool, enabled, setEnabled, enabledChanged) = true;
    PROPERTY_MUTABLE(EventFilter::Scope, scope, setScope, scopeChanged) = Scope::Parent;
    PROPERTY_MUTABLE(bool, eventProperties, setEventProperties, eventPropertiesChanged) = true;

    void classBegin() override { }
    void componentComplete() override { installEventFilter(); }
    bool eventFilter(QObject *watched, QEvent *event) override;

    QVariant eventTypes() const;

public slots:
    void setEventTypes(const QVariant &events);

signals:
    void eventTypesChanged();
    void eventFiltered(const QVariantMap &properties);

protected:
    void installEventFilter();

private:
    QMetaEnum m_metaEnum;
    QObject *m_watched;
    std::vector<QEvent::Type> m_eventTypes;
};

#endif // EVENTFILTER_H
