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
    Q_PROPERTY(bool kioskMode READ kioskMode WRITE setKioskMode NOTIFY kioskModeChanged)

public:
    enum LogLevel {
        LogBeginRange = 0,
        LogCritical = LogBeginRange,
        LogWarning = LogCritical,
        LogInfo,
        LogDebug,
        LogEndRange = LogDebug
    };
    Q_ENUM(LogLevel)

    Config(QObject *parent = nullptr);
    Config(const QString &fileName, QObject *parent = nullptr);

    QString fileName() const { return m_fileName; }
    int currentIndex() const { return m_currentIndex; }
    bool fullScreen() const { return m_fullScreen; }
    bool kioskMode() const { return m_kioskMode; }
    int logLevel() const { return m_logLevel; }

public slots:
    PROPERTY_WRITE_IMPL(int, currentIndex, setCurrentIndex, currentIndexChanged)
    PROPERTY_WRITE_IMPL(bool, fullScreen, setFullScreen, fullScreenChanged)
    PROPERTY_WRITE_IMPL(bool, kioskMode, setKioskMode, kioskModeChanged)
    PROPERTY_WRITE_IMPL(Config::LogLevel, logLevel, setLogLevel, logLevelChanged)

protected slots:
    void reconfigureLoggingFilterRules();

signals:
    void fileNameChanged(const QString &fileName);
    void currentIndexChanged(int currentIndex);
    void fullScreenChanged(bool fullScreen);
    void kioskModeChanged(bool kioskMode);
    void logLevelChanged(int logLevel);

private:
    QString m_fileName;
    int m_currentIndex;
    bool m_fullScreen;
    bool m_kioskMode;
    Config::LogLevel m_logLevel;
};

#endif // CONFIG_H
