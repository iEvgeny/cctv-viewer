#include "eventfilter.h"

#include <QJSValue>
#include <QMouseEvent>
#include <QCoreApplication>

QMetaEnum EventFilter::m_metaEnum(QMetaEnum::fromType<QEvent::Type>());

EventFilter::EventFilter(QObject *parent)
    : QObject(parent)
    , m_watched(nullptr)
{
    connect(this, &EventFilter::scopeChanged, this, &EventFilter::installEventFilter);
}

bool EventFilter::eventFilter([[maybe_unused]] QObject *watched, QEvent *event)
{
    auto type = event->type();

    if (m_enabled && std::find(m_events.begin(), m_events.end(), type) != m_events.end()) {
        QVariantMap properties;

        if (m_eventProperties) {
            properties.insert("type", m_metaEnum.valueToKey(type));

            switch (type) {
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

void EventFilter::prepareEvents(QStringList events)
{
    m_events.clear();

    for (const auto &i : events) {
        auto type = m_metaEnum.keyToValue(i.toUtf8());
        if (type < 0) {
            return;
        }
        m_events.push_back(static_cast<QEvent::Type>(type));
    }
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

void EventFilter::setEventTypes(QmlAVPropertyType<QStringList> events)
{
    if (eventTypes() == events) {
        return;
    }

    prepareEvents(events);

    emit eventTypesChanged(events);
}
