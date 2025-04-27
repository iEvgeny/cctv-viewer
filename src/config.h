#ifndef CONFIG_H
#define CONFIG_H

#include <QObject>

#include "utils.h"

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

    Config(QObject *parent = nullptr);
    Config(const QString &fileName, QObject *parent = nullptr);

    PROPERTY_CONST(QString, fileName);
    PROPERTY_MUTABLE(int, currentIndex, setCurrentIndex, currentIndexChanged) = -1;
    PROPERTY_MUTABLE(bool, fullScreen, setFullScreen, fullScreenChanged) = false;
    PROPERTY_MUTABLE(bool, kioskMode, setKioskMode, kioskModeChanged) = false;
    PROPERTY_MUTABLE(Config::LogLevel, logLevel, setLogLevel, logLevelChanged) = Config::LogInfo;

protected slots:
    void reconfigureLoggingFilterRules();
};

#endif // CONFIG_H
