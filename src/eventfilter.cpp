#include "eventfilter.h"
#include "qevent.h"

EventFilter::EventFilter(QObject *parent)
    : QObject(parent)
    , m_enabled(true)
    , m_scope(Scope::Parent)
    , m_watched(nullptr)
    , m_eventType(QEvent::None)
    , m_eventProperties(true)
{
    m_metaEnum = QMetaEnum::fromType<QEvent::Type>();
}

bool EventFilter::eventFilter([[maybe_unused]] QObject *watched, QEvent *event)
{
    if (m_enabled && event->type() == m_eventType) {
        QVariantMap properties;

        if (m_eventProperties) {
            switch (m_eventType) {
            case QEvent::MouseMove:
            case QEvent::MouseButtonPress:
            case QEvent::MouseButtonRelease: {
                QMouseEvent *e = static_cast<QMouseEvent *>(event);
                properties.insert("x", e->x());
                properties.insert("y", e->y());
                // TODO: Extend properties
                break;
            }
            // TODO: Handle other event types
            default:
                break;
            }
        }

        emit eventFiltered(properties);
    }

    return false;
}

void EventFilter::setEnabled(bool enabled)
{
    if (m_enabled == enabled) {
        return;
    }

    m_enabled = enabled;

    emit enabledChanged();
}

void EventFilter::setScope(Scope scope)
{
    if (m_scope == scope) {
        return;
    }

    m_scope = scope;

    if (m_watched) {
        installEventFilter();
    }

    emit scopeChanged();
}

void EventFilter::setEventType(QString eventType)
{
    auto value = m_metaEnum.keyToValue(eventType.toLatin1());
    if (value < 0 || m_eventType == static_cast<QEvent::Type>(value)) {
        return;
    }

    m_eventType = static_cast<QEvent::Type>(value);

    emit eventTypeChanged();
}

void EventFilter::setEventProperties(bool enabled)
{
    if (m_eventProperties == enabled) {
        return;
    }

    m_eventProperties = enabled;

    emit eventPropertiesChanged();
}

void EventFilter::installEventFilter()
{
    if (m_watched) {
        m_watched->removeEventFilter(this);
    }

    m_watched = (m_scope == Scope::Application) ? QCoreApplication::instance() : parent();
    if (m_watched) {
        m_watched->installEventFilter(this);
    }
}
