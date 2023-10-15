#include <algorithm>
#include "context.h"

Context::~Context()
{
    delete m_config;
}

void Context::init()
{
    QCommandLineOption configOption({{"c", "config"}, tr("Path to the config file."), "config"});
    QCommandLineOption presetOption({{"p", "preset"}, tr("Index of the current preset."), "preset"});
    QCommandLineOption fullScreenOption({{"f", "full-screen"}, tr("Force full-screen mode.")});
    QCommandLineOption kioskModeOption({{"k", "kiosk"}, tr("Kiosk mode functionality.")});
    QCommandLineOption logOption({{"l", "log"}, tr("Log level [%1...%2].").arg(Config::LogBeginRange).arg(Config::LogEndRange), "level"});

    parseCommandLineOptions({configOption,
                            presetOption,
                            fullScreenOption,
                            kioskModeOption,
                            logOption});

    if (m_commandLineParser.isSet(configOption)) {
        m_config = new Config(m_commandLineParser.value(configOption));
    } else {
        m_config = new Config();
    }
    if (m_commandLineParser.isSet(presetOption)) {
        m_config->setCurrentIndex(m_commandLineParser.value(presetOption).toInt());
    }
    m_config->setFullScreen(m_commandLineParser.isSet(fullScreenOption));
    m_config->setKioskMode(m_commandLineParser.isSet(kioskModeOption));
    if (m_commandLineParser.isSet(logOption)) {
        auto level = std::clamp(m_commandLineParser.value(logOption).toInt(),
                                static_cast<int>(Config::LogBeginRange),
                                static_cast<int>(Config::LogEndRange));
        m_config->setLogLevel(static_cast<Config::LogLevel>(level));
    }
}

 void Context::parseCommandLineOptions(const QList<QCommandLineOption> &options)
{
    m_commandLineParser.setApplicationDescription(tr("CCTV Viewer - viewer and mounter video streams."));
    m_commandLineParser.addHelpOption();
    m_commandLineParser.addVersionOption();

    m_commandLineParser.addOptions(options);

    QCoreApplication *app = QCoreApplication::instance();
    if (app) {
        m_commandLineParser.process(*app);
    }
}
