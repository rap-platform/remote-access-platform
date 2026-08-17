#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>
#include "SessionClient.h"
#include "ThemeManager.h"
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

    auto themeManager = new rap::client::ThemeManager(&app);
    engine.rootContext()->setContextProperty("themePalette", themeManager);

    auto frameProvider = new rap::client::VideoFrameProvider();
    engine.addImageProvider("frameprovider", frameProvider);
    engine.rootContext()->setContextProperty("frameProvider", frameProvider);

    auto sessionClient = new rap::client::SessionClient(frameProvider, &app);
    engine.rootContext()->setContextProperty("sessionClient", sessionClient);

    // Resolve QML Main.qml location robustly
    QString appDir = app.applicationDirPath();
    QStringList candidates = {
        appDir + "/qml/Main.qml",
        appDir + "/../../apps/client/qml/Main.qml",
        QDir::currentPath() + "/apps/client/qml/Main.qml",
        QDir::currentPath() + "/qml/Main.qml"
    };

    QString resolvedPath;
    for (const QString &path : candidates) {
        if (QFileInfo::exists(path)) {
            resolvedPath = QFileInfo(path).absoluteFilePath();
            break;
        }
    }

    if (resolvedPath.isEmpty()) {
        qCritical() << "[Client] Could not find Main.qml in candidates:" << candidates;
        return -1;
    }

    qInfo() << "[Client] Loading QML Main Interface from:" << resolvedPath;

    QString qmlDir = QFileInfo(resolvedPath).absolutePath();
    engine.addImportPath(qmlDir);

#ifdef ENABLE_HOT_RELOAD
    qInfo() << "[Client] Initializing QML Hot Reload Manager devtool...";
    auto hotReload = new rap::client::dev::HotReloadManager(&engine, &app);
    hotReload->watchDirectory(qmlDir);
#endif

    engine.load(QUrl::fromLocalFile(resolvedPath));

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "[Client] Failed to load QML interface!";
        return -1;
    }

    return app.exec();
}
