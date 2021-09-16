#ifndef CONFIG_H
#define CONFIG_H

#include <QtCore>

#include "global.h"

class Config : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString fileName READ fileName NOTIFY fileNameChanged)
    Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY currentIndexChanged)

public:
    explicit Config(QObject *parent = nullptr);
    explicit Config(const QString &fileName, QObject *parent = nullptr);

    QString fileName() const { return m_fileName; }
    int currentIndex() const { return m_currentIndex; }

public slots:
    Q_PROPERTY_WRITE_IMPL(int, currentIndex, setCurrentIndex, currentIndexChanged)

signals:
    void fileNameChanged(const QString &fileName);
    void currentIndexChanged(int currentIndex);

private:
    QString m_fileName;
    int m_currentIndex;
};

#endif // CONFIG_H
