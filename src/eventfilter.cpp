#include "eventfilter.h"

#include <QJSValue>
#include <QMouseEvent>
#include <QCoreApplication>

EventFilter::EventFilter(QObject *parent)
    : QObject(parent)
    , m_metaEnum(QMetaEnum::fromType<QEvent::Type>())
    , m_watched(nullptr)
{
    connect(this, &EventFilter::scopeChanged, this, &EventFilter::installEventFilter);
}

bool EventFilter::eventFilter([[maybe_unused]] QObject *watched, QEvent *event)
{
    auto type = event->type();

    if (m_enabled && std::find(m_eventTypes.begin(), m_eventTypes.end(), type) != m_eventTypes.end()) {
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

QVariant EventFilter::eventTypes() const
{
    QStringList list;
    for (auto i : m_eventTypes) {
        list.append(m_metaEnum.valueToKey(i));
    }
    return list;
}

void EventFilter::setEventTypes(const QVariant &events)
{
    auto variant = events.value<QJSValue>().toVariant();
    auto list = variant.toStringList();

    if (eventTypes() == list) {
        return;
    }

    m_eventTypes.clear();

    for (const auto &i : qAsConst(list)) {
        auto type = m_metaEnum.keyToValue(i.toLatin1());
        if (type < 0) {
            return;
        }
        m_eventTypes.push_back(static_cast<QEvent::Type>(type));
    }

    emit eventTypesChanged();
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
