#include "config.h"

Config::Config(QObject *parent)
    : Config(QSettings().fileName(), parent)
{
}

Config::Config(const QString &fileName, QObject *parent)
    : QObject(parent),
      m_fileName(fileName),
      m_currentIndex(-1),
      m_fullScreen(false)
{
    // TODO:
}
