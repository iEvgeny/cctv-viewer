#include <signal.h>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QTranslator>
#include "quickenums.h"

void registerQmlTypes() {
    // Enums
    qmlRegisterUncreatableType<QuickViewport>("CCTV_Viewer.Enums", 1, 0, "Viewport", "Uncreatable type!");
}

int main(int argc, char *argv[]) {
// NOTE: This code is actual only when using QtMultimedia.
#if defined(Q_OS_LINUX)
    // Ignore the SIGPIPE signal. Can be raised by librtmp.
    signal(SIGPIPE, SIG_IGN);
#endif

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

#if defined(APP_NAME)
    QCoreApplication::setApplicationName(QLatin1String(APP_NAME));
#endif
#if defined(APP_VERSION)
    QCoreApplication::setApplicationVersion(QLatin1String(APP_VERSION));
#endif
#if defined(ORG_NAME)
    QCoreApplication::setOrganizationName(QLatin1String(ORG_NAME));
#endif
#if defined(ORG_DOMAIN)
    QCoreApplication::setOrganizationDomain(QLatin1String(ORG_DOMAIN));
#endif

    registerQmlTypes();

    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    QTranslator translator;
    const QString locale = QLocale::system().name();
    translator.load(QLatin1String("cctv-viewer_") + locale, QLatin1String(":/res/translations/"));
    app.installTranslator(&translator);

    // NOTE: Debug
    // Testing Right-to-left User Interfaces...
    // (This code must be removed!!!)
//    app.setLayoutDirection(Qt::RightToLeft);

    engine.load(QUrl(QLatin1String("qrc:///src/qml/main.qml")));

    QObject *topLevel = engine.rootObjects().value(0);
    QQuickWindow *window = qobject_cast<QQuickWindow *>(topLevel);
    if (!window) {
        qWarning("Error: Your root item has to be a Window.");
        return -1;
    }

    window->setIcon(QIcon(QLatin1String(":/res/icons/cctv-viewer.ico")));

    return app.exec();
}
