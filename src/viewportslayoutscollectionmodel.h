#ifndef VIEWPORTSLAYOUTSCOLLECTIONMODEL_H
#define VIEWPORTSLAYOUTSCOLLECTIONMODEL_H

#include <QtCore>
#include <QQmlEngine>

#include "viewportslayoutmodel.h"

class ViewportsLayoutsCollectionModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(QQmlListProperty<ViewportsLayoutModel> models READ models)
    Q_CLASSINFO("DefaultProperty", "models")

public:
    ViewportsLayoutsCollectionModel(QObject *parent = nullptr);

    enum ModelRoles {
        LayoutModel = Qt::UserRole + 1
    };

    // QAbstractItemModel interface
    QVariant data(const QModelIndex &index, int role) const override;
    // bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;
    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;

    // Model control interface
    Q_INVOKABLE int count() const { return m_models.size(); }
    Q_INVOKABLE ViewportsLayoutModel *get(int index) const { return m_models.value(index); }
    Q_INVOKABLE ViewportsLayoutModel *set(int index, ViewportsLayoutModel *p);
    Q_INVOKABLE void clear();
    Q_INVOKABLE ViewportsLayoutModel *insert(int index, ViewportsLayoutModel *p);
    Q_INVOKABLE void remove(int index, int count = 1);
    Q_INVOKABLE ViewportsLayoutModel *append(ViewportsLayoutModel *p = nullptr) { return insert(m_models.size(), p); }
    Q_INVOKABLE void resize(int count);

    Q_INVOKABLE void fromJSValue(const QVariantList &models);
    Q_INVOKABLE QVariantList toJSValue() const;

    // Default property
public:
    QQmlListProperty<ViewportsLayoutModel> models();
private:
    static void appendModel(QQmlListProperty<ViewportsLayoutModel> *list, ViewportsLayoutModel *p);
    static int modelsCount(QQmlListProperty<ViewportsLayoutModel> *list);
    static ViewportsLayoutModel *model(QQmlListProperty<ViewportsLayoutModel> *list, int index);
    static void clearModels(QQmlListProperty<ViewportsLayoutModel> *list);

signals:
    void changed();
    void countChanged(int count);

private:
    QVector<ViewportsLayoutModel*> m_models;
};

QML_DECLARE_TYPE(ViewportsLayoutsCollectionModel)

#endif // VIEWPORTSLAYOUTSCOLLECTIONMODEL_H
