#ifndef CONFIG_H
#define CONFIG_H

#include <QObject>

#include "qmlavpropertyhelpers.h"

class Config : public QObject
{
    Q_OBJECT

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

    QMLAV_PROPERTY_CONST(QString, fileName);
    QMLAV_PROPERTY(int, currentIndex, setCurrentIndex, currentIndexChanged) = -1;
    QMLAV_PROPERTY(bool, fullScreen, setFullScreen, fullScreenChanged) = false;
    QMLAV_PROPERTY(bool, kioskMode, setKioskMode, kioskModeChanged) = false;
    QMLAV_PROPERTY(Config::LogLevel, logLevel, setLogLevel, logLevelChanged) = Config::LogInfo;

public:
    Config(QObject *parent = nullptr);
    Config(const QString &fileName, QObject *parent = nullptr);

protected slots:
    void reconfigureLoggingFilterRules();
};

#endif // CONFIG_H
