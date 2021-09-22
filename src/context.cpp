#include "context.h"

Context::~Context()
{
    if (m_config) {
        delete m_config;
    }
}

void Context::init()
{
    QCommandLineOption configOption({{"c", "config"}, tr("Path to the config file."), "config"});
    QCommandLineOption presetOption({{"p", "preset"}, tr("Index of the current preset."), "preset"});
    QCommandLineOption fullScreenOption({{"f", "full-screen"}, tr("Force full-screen mode.")});

    parseCommandLineOptions({configOption,
                            presetOption,
                            fullScreenOption});

    if (m_commandLineParser.isSet(configOption)) {
        m_config = new Config(m_commandLineParser.value(configOption));
    } else {
        m_config = new Config();
    }
    if (m_commandLineParser.isSet(presetOption)) {
        m_config->setCurrentIndex(m_commandLineParser.value(presetOption).toUInt());
    }
    m_config->setFullScreen(m_commandLineParser.isSet(fullScreenOption));
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
