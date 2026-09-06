#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QQmlEngine>
#include <QSignalSpy>
#include <QTest>

#include "../src/dev/HotReloadManager.h"

class TestHotReload : public QObject {
    Q_OBJECT

private slots:
    void testHotReloadWatcher() {
        QQmlEngine engine;
        rap::client::dev::HotReloadManager manager(&engine);

        QString tempDir = QDir::temp().filePath("rap_hot_reload_test");
        QDir().mkpath(tempDir);

        QString testQmlPath = QDir(tempDir).filePath("Test.qml");
        QFile file(testQmlPath);
        QVERIFY(file.open(QIODevice::WriteOnly | QIODevice::Text));
        file.write("import QtQuick\nItem {}\n");
        file.close();

        manager.watchDirectory(tempDir);
        QVERIFY(manager.isActive());

        QSignalSpy spy(&manager, &rap::client::dev::HotReloadManager::qmlReloaded);

        // Modify QML file to trigger file system watcher
        QTest::qWait(100);
        QVERIFY(file.open(QIODevice::Append | QIODevice::Text));
        file.write("// Modified\n");
        file.close();

        QVERIFY(spy.wait(2000) || spy.count() > 0);

        QFile::remove(testQmlPath);
        QDir().rmdir(tempDir);
    }
};

QTEST_MAIN(TestHotReload)
#include "test_hot_reload.moc"
