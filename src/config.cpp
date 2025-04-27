#include "config.h"

#include <QSettings>
#include <QLoggingCategory>

Config::Config(QObject *parent)
    : Config(QSettings().fileName(), parent)
{
}

Config::Config(const QString &fileName, QObject *parent)
    : QObject(parent),
      m_fileName(fileName)
{
    qSetMessagePattern("%{message}");
    reconfigureLoggingFilterRules();

    connect(this, &Config::logLevelChanged, this, &Config::reconfigureLoggingFilterRules);
}

void Config::reconfigureLoggingFilterRules()
{
    QLoggingCategory::setFilterRules(QString("%1.critical=%2\n"
                                             "%1.warning=%3\n"
                                             "%1.info=%4\n"
                                             "%1.debug=%5")
                                             .arg("qmlav")
                                             .arg(m_logLevel >= Config::LogCritical ? "true" : "false",
                                                  m_logLevel >= Config::LogWarning ? "true" : "false",
                                                  m_logLevel >= Config::LogInfo ? "true" : "false",
                                                  m_logLevel >= Config::LogDebug ? "true" : "false"));
}
