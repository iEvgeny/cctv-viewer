#ifndef EVENTFILTER_H
#define EVENTFILTER_H

#include <QQmlParserStatus>
#include <QMetaEnum>
#include <QEvent>

#include "qmlavpropertyhelpers.h"

class EventFilter : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)

public:
    enum class Scope {
        Application,
        Parent
    };
    Q_ENUM(Scope)

    QMLAV_PROPERTY(bool, enabled, setEnabled, enabledChanged) = true;
    QMLAV_PROPERTY(EventFilter::Scope, scope, setScope, scopeChanged) = Scope::Parent;
    QMLAV_PROPERTY_DECL(QStringList, eventTypes, setEventTypes, eventTypesChanged);
    QMLAV_PROPERTY(bool, eventProperties, setEventProperties, eventPropertiesChanged) = true;

public:
    EventFilter(QObject *parent = nullptr);

    void classBegin() override { }
    void componentComplete() override { installEventFilter(); }
    bool eventFilter(QObject *watched, QEvent *event) override;

signals:
    void eventFiltered(const QVariantMap &properties);

protected:
    void prepareEvents(QStringList events);
    void installEventFilter();

private:
    static QMetaEnum m_metaEnum;
    QObject *m_watched;
    std::vector<QEvent::Type> m_events;
};

#endif // EVENTFILTER_H
