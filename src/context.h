#ifndef CONTEXT_H
#define CONTEXT_H

#include <QCommandLineParser>

#include "config.h"

class Context : public QObject
{
    Q_OBJECT

    Q_PROPERTY(Config *config READ config CONSTANT)

public:
    explicit Context(QObject *parent = nullptr) : QObject(parent) { }
    virtual ~Context();

    static void init();

    static Config *config() { return m_config; }

private:
    static void parseCommandLineOptions(const QList<QCommandLineOption> &options);

private:
    inline static Config *m_config = nullptr;
    inline static QCommandLineParser m_commandLineParser;
};

#endif // CONTEXT_H
