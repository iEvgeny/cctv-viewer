#include "viewportslayoutscollectionmodel.h"

ViewportsLayoutsCollectionModel::ViewportsLayoutsCollectionModel(QObject *parent) : QAbstractListModel(parent)
{
    connect(this, &ViewportsLayoutsCollectionModel::countChanged, this, &ViewportsLayoutsCollectionModel::changed);
}

QVariant ViewportsLayoutsCollectionModel::data(const QModelIndex &index, int role) const
{
    if (!hasIndex(index.row(), index.column()) || role != LayoutModel) {
        return QVariant();
    }

    return QVariant::fromValue(get(index.row()));
}

QHash<int, QByteArray> ViewportsLayoutsCollectionModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[LayoutModel] = "layoutModel";

    return roles;
}

int ViewportsLayoutsCollectionModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_models.size();
}

ViewportsLayoutModel *ViewportsLayoutsCollectionModel::set(int index, ViewportsLayoutModel *p)
{
    if (p == get(index)) {
        return p;
    }

    if (index >= 0 && index < m_models.size()) {
        m_models[index] = p;

        QModelIndex modelIndex = QAbstractListModel::index(index, 0);
        emit dataChanged(modelIndex, modelIndex);
    }

    return p;
}

void ViewportsLayoutsCollectionModel::clear()
{
    beginResetModel();
    m_models.clear();
    endResetModel();
}

ViewportsLayoutModel *ViewportsLayoutsCollectionModel::insert(int index, ViewportsLayoutModel *p)
{
    if (index >= 0 && index <= m_models.size()) {
        QQmlEngine *engine = qmlEngine(this);

        Q_ASSERT(engine != nullptr);

        beginInsertRows(QModelIndex(), index, index);

        if (p == nullptr) {
            p = new ViewportsLayoutModel(this);
            QQmlEngine::setContextForObject(p, engine->rootContext());
        }

        Q_ASSERT(p != nullptr);

        m_models.insert(index, p);
        connect(p, &ViewportsLayoutModel::changed, this, &ViewportsLayoutsCollectionModel::changed);
        endInsertRows();

        emit countChanged(m_models.size());
    }

    return p;
}

void ViewportsLayoutsCollectionModel::remove(int index, int count)
{
    beginRemoveRows(QModelIndex(), index, index + count - 1);
    m_models.remove(index, count);
    endRemoveRows();

    emit countChanged(m_models.size());
}

void ViewportsLayoutsCollectionModel::resize(int count)
{
    if (count > m_models.size()) {
        while (count - m_models.size() > 0) {
            append();
        }
    }

    if (count < m_models.size()) {
        remove(count, m_models.size() - count);
    }
}

void ViewportsLayoutsCollectionModel::fromJSValue(const QVariantList &models)
{
    if (models.size() != m_models.size()) {
        resize(models.size());
    }

    for (int i = 0; i < m_models.size(); ++i) {
        get(i)->fromJSValue(models.at(i).toMap());
    }
}

QVariantList ViewportsLayoutsCollectionModel::toJSValue() const
{
    QVariantList collection;

    for (int i = 0; i < m_models.size(); ++i) {
         QVariantMap model = qobject_cast<ViewportsLayoutModel*>(get(i))->toJSValue();
         collection.append(model);
    }

    return collection;
}

QQmlListProperty<ViewportsLayoutModel> ViewportsLayoutsCollectionModel::models()
{
    return QQmlListProperty<ViewportsLayoutModel>(this, this,
                                                  &ViewportsLayoutsCollectionModel::appendModel,
                                                  &ViewportsLayoutsCollectionModel::modelsCount,
                                                  &ViewportsLayoutsCollectionModel::model,
                                                  &ViewportsLayoutsCollectionModel::clearModels);
}

void ViewportsLayoutsCollectionModel::appendModel(QQmlListProperty<ViewportsLayoutModel> *list, ViewportsLayoutModel *p)
{
    reinterpret_cast<ViewportsLayoutsCollectionModel *>(list->data)->append(p);
}

int ViewportsLayoutsCollectionModel::modelsCount(QQmlListProperty<ViewportsLayoutModel> *list)
{
    return reinterpret_cast<ViewportsLayoutsCollectionModel *>(list->data)->count();
}

ViewportsLayoutModel *ViewportsLayoutsCollectionModel::model(QQmlListProperty<ViewportsLayoutModel> *list, int index)
{
    QObject *obj = reinterpret_cast<ViewportsLayoutsCollectionModel *>(list->data)->get(index);
    return reinterpret_cast<ViewportsLayoutModel *>(obj);
}

void ViewportsLayoutsCollectionModel::clearModels(QQmlListProperty<ViewportsLayoutModel> *list)
{
    reinterpret_cast<ViewportsLayoutsCollectionModel *>(list->data)->clear();
}
