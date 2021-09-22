#ifndef CONFIG_H
#define CONFIG_H

#include <QtCore>

#include "global.h"

class Config : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString fileName READ fileName NOTIFY fileNameChanged)
    Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(bool fullScreen READ fullScreen WRITE setFullScreen NOTIFY fullScreenChanged)

public:
    explicit Config(QObject *parent = nullptr);
    explicit Config(const QString &fileName, QObject *parent = nullptr);

    QString fileName() const { return m_fileName; }
    int currentIndex() const { return m_currentIndex; }
    bool fullScreen() const { return m_fullScreen; }

public slots:
    Q_PROPERTY_WRITE_IMPL(int, currentIndex, setCurrentIndex, currentIndexChanged)
    Q_PROPERTY_WRITE_IMPL(bool, fullScreen, setFullScreen, fullScreenChanged)

signals:
    void fileNameChanged(const QString &fileName);
    void currentIndexChanged(int currentIndex);
    void fullScreenChanged(bool fullScreen);

private:
    QString m_fileName;
    int m_currentIndex;
    bool m_fullScreen;
};

#endif // CONFIG_H
