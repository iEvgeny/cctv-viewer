#include "viewportslayoutmodel.h"

ViewportsLayoutItem::ViewportsLayoutItem(QObject *parent)
    : QObject(parent), m_rowSpan(1), m_columnSpan(1), m_visible(Visible::Visible), m_volume(0.0)
{
    const QMetaObject* metaObject = this->metaObject();
    QMetaMethod changedMethod = QMetaMethod::fromSignal(&ViewportsLayoutItem::changed);
    for(int i = metaObject->methodOffset(); i < metaObject->methodCount(); ++i) {
        QMetaMethod method = metaObject->method(i);
        if (method.methodType() == QMetaMethod::Signal && method != changedMethod) {
            connect(this, method, this, changedMethod);
        }
    }
}

ViewportsLayoutModel::ViewportsLayoutModel(QObject *parent)
    : QAbstractListModel(parent),
      m_columns(0),
      m_rows(0),
      m_aspectRatio(16, 9)
{
    connect(this, &ViewportsLayoutModel::dataChanged, this, &ViewportsLayoutModel::changed);
    connect(this, &ViewportsLayoutModel::sizeChanged, this, &ViewportsLayoutModel::changed);
}

QVariant ViewportsLayoutModel::data(const QModelIndex &index, int role) const
{
    QString key = roleNames().value(role);

    if (!hasIndex(index.row(), index.column())) {
        return QVariant();
    }

    return get(index.row())->property(key.toUtf8());
}

QHash<int, QByteArray> ViewportsLayoutModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[UrlRole] = "url";
    roles[ColumnSpanRole] = "columnSpan";
    roles[RowSpanRole] = "rowSpan";
    roles[VisibleRole] = "visible";
    roles[VolumeRole] = "volume";

    return roles;
}

int ViewportsLayoutModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_items.size();
}

ViewportsLayoutItem *ViewportsLayoutModel::set(int index, ViewportsLayoutItem *p)
{
    if (p == get(index)) {
        return p;
    }

    if (index >= 0 && index < m_items.size()) {
        m_items[index] = p;

        QModelIndex modelIndex = QAbstractListModel::index(index, 0);
        emit dataChanged(modelIndex, modelIndex);
    }

    return p;
}

void ViewportsLayoutModel::clear() {
    beginResetModel();
    m_items.clear();
    endResetModel();
}

void ViewportsLayoutModel::resize(int columns, int rows)
{
    int count = rows * columns;

    if (rows >= 0 && columns >= 0) {
        m_columns = columns;
        m_rows = rows;

        if (count > m_items.size()) {
            beginInsertRows(QModelIndex(), m_items.size(), count - 1);
            normalize();
            endInsertRows();
        } else if (count < m_items.size()) {
            beginRemoveRows(QModelIndex(), count, m_items.size() - 1);
            normalize();
            endRemoveRows();
        } else {
            normalize();
        }
    }
}

void ViewportsLayoutModel::normalize()
{
    int count = m_columns * m_rows;

    // Resize
    if (m_items.size() != count) {
        m_items.resize(count);
        emit sizeChanged(QSize(m_columns, m_rows));
    }

normalize:
    // Mormalize properties
    for (int index = 0; index < m_items.size(); ++index) {
        auto item = get(index);

        if (item == nullptr) {
            QQmlEngine *engine = qmlEngine(this);

            Q_ASSERT(engine != nullptr);

            item = new ViewportsLayoutItem(this);
            QQmlEngine::setContextForObject(item, engine->rootContext());

            connect(item, &ViewportsLayoutItem::changed, [=] {
                for (int i = 0; i < m_items.size(); ++i) {
                    if (item == m_items.at(i)) {
                        QModelIndex index = createIndex(i, 0);
                        emit reinterpret_cast<ViewportsLayoutModel*>(this)->dataChanged(index, index);
                    }
                }
            });

            set(index, item);
        } else {
            int span = 1;
            int columnSpan = clamp(item->property("columnSpan").toInt(), 1, m_columns - column(index));
            int rowSpan = clamp(item->property("rowSpan").toInt(), 1, m_rows - row(index));

            if (columnSpan != m_columns || rowSpan != m_rows) {
                span = std::min(rowSpan, columnSpan);
            }

            item->setProperty("columnSpan", span);
            item->setProperty("rowSpan", span);
            item->setProperty("visible", static_cast<int>(ViewportsLayoutItem::Visible::Visible));
            item->setProperty("volume", clamp(item->property("volume").toDouble(), 0.0, 1.0));
        }
    }

    for (int index = 0; index < m_items.size(); ++index) {
        auto item = get(index);

        if (item->property("visible").toInt() == static_cast<int>(ViewportsLayoutItem::Visible::Visible)) {
            int columnSpan = item->property("columnSpan").toInt();
            int rowSpan = item->property("rowSpan").toInt();

            // Iterate hidden elements
            for (int r = 0; r < rowSpan; ++r) {
                for (int c = 0; c < columnSpan; ++c) {
                    int hiddenIndex = dataIndex(column(index) + c, row(index) + r);
                    if (hiddenIndex != index) {
                        auto hiddenItem = get(hiddenIndex);
                        if (hiddenItem->property("visible").toInt() == static_cast<int>(ViewportsLayoutItem::Visible::Visible)) {
                            hiddenItem->setProperty("columnSpan", -c);
                            hiddenItem->setProperty("rowSpan", -r);
                            hiddenItem->setProperty("visible", static_cast<int>(ViewportsLayoutItem::Visible::Hidden));
                        } else {
                            // Span collision
                            item->setProperty("columnSpan", 1);
                            item->setProperty("rowSpan", 1);
                            goto normalize;
                        }
                    }
                }
            }
        }

        emit dataChanged(QModelIndex(), QModelIndex());
    }
}

void ViewportsLayoutModel::fromJSValue(QVariantMap model)
{
    QVariant val;

    if (model.contains("size")) {
        val = model.value("size");
        if (val.canConvert(QMetaType::QVariantMap)) {
            int width = val.toMap().value("width").toInt();
            int height = val.toMap().value("height").toInt();
            setSize(QSize(width, height));
        }
    } else if (model.contains("division")) {
        // Old property
        int size = model.value("division").toInt();
        setSize(QSize(size, size));
    }

    if (model.contains("aspectRatio")) {
        val = model.value("aspectRatio");
        if (val.canConvert(QMetaType::QVariantMap)) {
            int width = val.toMap().value("width").toInt();
            int height = val.toMap().value("height").toInt();
            setAspectRatio(QSize(width, height));
        } else if (val.canConvert(QMetaType::QString)) {
            // Old format
            QStringList strList = val.toString().split(':');
            if (strList.size() == 2) {
                setAspectRatio(QSize(strList.at(0).toInt(), strList.at(1).toInt()));
            }
        }
    }

    if (model.contains("items")) {
        val = model.value("items");
    } else if (model.contains("model")) {
        // Old property
        val = model.value("model");
    }
    if (val.canConvert(QMetaType::QVariantList)) {
        QVariantList items = val.toList();
        for (int i = 0; i < std::min(m_items.size(), items.size()); ++i) {
            QHashIterator<int, QByteArray> role(roleNames());
            while (role.hasNext()) {
                role.next();

                const char *name = role.value();
                QVariantMap item = items.at(i).toMap();
                m_items.at(i)->setProperty(name, item.value(name));
            }
        }
    }

    normalize();
}

QVariantMap ViewportsLayoutModel::toJSValue() const
{
    QVariantMap model;
    QVariantList items;

    for (int i = 0; i < m_items.size(); ++i) {
        QVariantMap item;
        if (get(i) != nullptr) {
            const QMetaObject* metaObject = get(i)->metaObject();
            for(int j = metaObject->propertyOffset(); j < metaObject->propertyCount(); ++j) {
                const char *name = metaObject->property(j).name();
                int hashKey = roleNames().key(name);
                if (hashKey) {
                    item[name] = get(i)->property(name);
                }
            }
            items.append(item);
        }
    }

    model["size"] = size();
    model["aspectRatio"] = m_aspectRatio;
    model["items"] = items;

    return model;
}

void ViewportsLayoutModel::setSize(QSize size)
{
    if (size == QSize(m_columns, m_rows)) {
        return;
    }

    resize(size.width(), size.height());

    emit sizeChanged(size);
}

void ViewportsLayoutModel::setAspectRatio(QSize ratio)
{
    if (ratio == m_aspectRatio) {
        return;
    }

    m_aspectRatio = ratio;

    emit aspectRatioChanged(ratio);
}
