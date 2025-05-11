#ifndef VIEWPORTSLAYOUTMODEL_H
#define VIEWPORTSLAYOUTMODEL_H

#include <math.h>

#include <QQmlEngine>
#include <QAbstractListModel>
#include <QSize>

#include "qmlavpropertyhelpers.h"

// TODO: Reimplement this with QSize/QRect as a span property
class ViewportsLayoutItem : public QObject
{
    Q_OBJECT

public:
    enum class Visible {
        Visible,
        Hidden
    };
    Q_ENUM(Visible)

    QMLAV_PROPERTY(QString, url, setUrl, urlChanged);
    QMLAV_PROPERTY(int, rowSpan, setRowSpan, rowSpanChanged) = 1;
    QMLAV_PROPERTY(int, columnSpan, setColumnSpan, columnSpanChanged) = 1;
    QMLAV_PROPERTY(ViewportsLayoutItem::Visible, visible, setVisible, visibleChanged) = Visible::Visible;
    QMLAV_PROPERTY(QVariant, volume, setVolume, volumeChanged) = 0.0;
    QMLAV_PROPERTY(QVariantMap, avFormatOptions, setAVFormatOptions, avFormatOptionsChanged);

public:
    ViewportsLayoutItem(QObject *parent = nullptr);

signals:
    void changed();
};
QML_DECLARE_TYPE(ViewportsLayoutItem)

class ViewportsLayoutModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(QSize size READ size WRITE setSize NOTIFY sizeChanged)

    QMLAV_PROPERTY(QSize, aspectRatio, setAspectRatio, aspectRatioChanged) = {16, 9};

public:
    ViewportsLayoutModel(QObject *parent = nullptr);

    // QAbstractItemModel interface
    virtual int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    virtual QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex &index, const QVariant &value, int role) override;
    virtual QHash<int, QByteArray> roleNames() const override { return m_roleNames; }

    // Model control interface
    Q_INVOKABLE QSize size() const { return QSize(m_columns, m_rows); }

    Q_INVOKABLE ViewportsLayoutItem *get(int index) const { return m_items.value(index); }
    Q_INVOKABLE ViewportsLayoutItem *get(int column, int row) const { return get(dataIndex(column, row)); }
    Q_INVOKABLE ViewportsLayoutItem *set(int index, ViewportsLayoutItem *p);
    Q_INVOKABLE ViewportsLayoutItem *set(int column, int row, ViewportsLayoutItem *p) { return set(dataIndex(column, row), p); }
    Q_INVOKABLE void clear();
    Q_INVOKABLE void resize(int columns, int rows);
    Q_INVOKABLE void normalize();

    Q_INVOKABLE void fromJSValue(const QVariantMap &model);
    Q_INVOKABLE QVariantMap toJSValue() const;

public slots:
    void setSize(const QSize &size);

signals:
    void changed();
    void sizeChanged(const QSize &size);

protected:
    int dataIndex(int column, int row) const { return m_columns * row + column; }
    int column(int index) const { return index % m_columns; }
    int row(int index) const { return std::floor(index / m_columns); }

private:
    template<class T>
    const T& clamp(const T& v, const T& lo, const T& hi)
    {
        Q_ASSERT(!(hi < lo));
        return (v < lo) ? lo : (hi < v) ? hi : v;
    }

    int m_columns;
    int m_rows;
    QHash<int, QByteArray> m_roleNames;
    QVector<ViewportsLayoutItem *> m_items;
};
QML_DECLARE_TYPE(ViewportsLayoutModel)

#endif // VIEWPORTSLAYOUTMODEL_H
