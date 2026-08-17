#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>
#include "VideoFrameProvider.h"
#include "logging/JsonLogger.h"

#ifdef ENABLE_HOT_RELOAD
#include "dev/HotReloadManager.h"
#endif

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("rap-client");
    app.setApplicationVersion("0.1.0");

    rap::common::logging::JsonLogger::instance().initialize();
    qInfo() << "[Client] Remote Access Platform Viewer launching...";

    QQmlApplicationEngine engine;

    auto frameProvider = new rap::client::VideoFrameProvider();
    engine.addImageProvider("frameprovider", frameProvider);

#ifdef ENABLE_HOT_RELOAD
    qInfo() << "[Client] Initializing QML Hot Reload Manager devtool...";
    auto hotReload = new rap::client::dev::HotReloadManager(&engine, &app);
    hotReload->watchDirectory(app.applicationDirPath() + "/../qml");
#endif

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));
    engine.load(QUrl::fromLocalFile(app.applicationDirPath() + "/../../apps/client/qml/Main.qml"));

    if (engine.rootObjects().isEmpty()) {
        qWarning() << "[Client] Falling back to QRC resource path for Main.qml";
        engine.load(url);
    }

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "[Client] Failed to load QML interface!";
        return -1;
    }

    return app.exec();
}
