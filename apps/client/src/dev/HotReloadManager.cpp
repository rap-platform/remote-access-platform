#include "HotReloadManager.h"
#include <QDebug>
#include <QDir>
#include <QDirIterator>

namespace rap::client::dev {

HotReloadManager::HotReloadManager(QQmlEngine *engine, QObject *parent)
    : QObject(parent), engine_(engine) {
    connect(&watcher_, &QFileSystemWatcher::fileChanged,
            this, &HotReloadManager::onFileOrDirectoryChanged);
    connect(&watcher_, &QFileSystemWatcher::directoryChanged,
            this, &HotReloadManager::onFileOrDirectoryChanged);
}

void HotReloadManager::watchDirectory(const QString &dirPath) {
    QDir dir(dirPath);
    if (!dir.exists()) {
        return;
    }

    QStringList paths;
    paths.append(dirPath);

    QDirIterator it(dirPath, QStringList() << "*.qml", QDir::Files, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        paths.append(it.next());
    }

    watcher_.addPaths(paths);
    emit activeChanged();
}

void HotReloadManager::onFileOrDirectoryChanged(const QString &path) {
    qDebug() << "[HotReload] File/Directory modified:" << path << "- Clearing QML cache";
    if (engine_) {
        engine_->clearComponentCache();
        emit qmlReloaded();
    }
}

} // namespace rap::client::dev
